import asyncio
import json
import re
import os
import uuid
import shutil
import signal
import tempfile
from typing import Tuple

from rich.progress import Progress, SpinnerColumn, TextColumn

from nexus_config import (
    console_terminal_interface,
    TEMP_IO_DIRECTORY,
    ACTIVE_AGENTS,
    APIKeyRotator,
    GEMINI_CLI_PATH,
)
from nexus_database import retrieve_ecosystem_context, save_verified_module
from nexus_compiler import AbsoluteOmniValidator, NativeLuauCompiler

# FAKTA MUTLAK: Hanya 1 request ke Gemini CLI pada satu waktu (Sequential Queue)
# Semaphore(1) memastikan agent benar-benar antri satu per satu, tidak ada spam paralel
CLI_EXECUTION_SEMAPHORE = asyncio.Semaphore(1)

# Global rate-limit backoff state
_GLOBAL_RATE_LIMIT_UNTIL: float = 0.0
_GLOBAL_RATE_LIMIT_LOCK = asyncio.Lock()

# Variabel aman untuk mencegah Markdown Parser UI memecah file secara visual
MARKDOWN_BLOCK = "```"


def extract_pure_luau_code(raw_payload: str) -> str:
    """Penghancur Markdown tangguh. Membersihkan sisa backtick dan spasi liar."""
    if not raw_payload:
        return ""
    code = raw_payload.strip()
    code = re.sub(r'^\s*```[a-zA-Z]*\s*\n*', '', code, flags=re.IGNORECASE)
    code = re.sub(r'\n*\s*```\s*$', '', code)
    return code.strip()


async def _wait_global_rate_limit():
    """Tunggu jika ada global rate-limit cooldown aktif."""
    import time
    global _GLOBAL_RATE_LIMIT_UNTIL
    now = time.monotonic()
    if now < _GLOBAL_RATE_LIMIT_UNTIL:
        wait_secs = _GLOBAL_RATE_LIMIT_UNTIL - now
        console_terminal_interface.print(
            f"[bold yellow][Global Rate Limit] Semua agent dalam cooldown. Menunggu {wait_secs:.0f} detik...[/bold yellow]"
        )
        await asyncio.sleep(wait_secs)


async def _set_global_rate_limit(cooldown_seconds: float = 60.0):
    """Aktifkan global cooldown agar semua agent berhenti sementara."""
    import time
    global _GLOBAL_RATE_LIMIT_UNTIL
    async with _GLOBAL_RATE_LIMIT_LOCK:
        new_until = time.monotonic() + cooldown_seconds
        if new_until > _GLOBAL_RATE_LIMIT_UNTIL:
            _GLOBAL_RATE_LIMIT_UNTIL = new_until
            console_terminal_interface.print(
                f"[bold red][Global Rate Limit] Cooldown diaktifkan selama {cooldown_seconds:.0f} detik.[/bold red]"
            )


async def execute_gemini_cli_pure(agent: dict, system_instruction: str, prompt_payload: str) -> Tuple[bool, str]:
    """
    EKSEKUTOR MUTLAK SEQUENTIAL (File-to-File IPC): 100% Native CLI Execution.
    DIPERBAIKI:
    - Semaphore(1) = hanya 1 request aktif pada satu waktu, agent benar-benar antri
    - Global rate-limit cooldown agar tidak spam saat quota habis
    - Fallback model otomatis Gemini 3.1 -> 3 -> 2.5
    - Tidak ada stdin/stdout pipe conflict
    """
    # Cek global rate limit sebelum masuk semaphore
    await _wait_global_rate_limit()

    async with CLI_EXECUTION_SEMAPHORE:
        # Cek lagi setelah masuk semaphore (mungkin berubah saat menunggu)
        await _wait_global_rate_limit()

        api_key = agent.get("api_key", "")
        if not api_key:
            return False, "API_KEY_KOSONG"

        unique_session_id = uuid.uuid4().hex
        temp_home_dir = os.path.join(TEMP_IO_DIRECTORY, f"gemini_cli_home_{unique_session_id}")

        try:
            os.makedirs(temp_home_dir, exist_ok=True)
            os.makedirs(os.path.join(temp_home_dir, ".gemini"), exist_ok=True)

            prompt_filepath = os.path.join(temp_home_dir, "input_prompt.txt")
            output_filepath = os.path.join(temp_home_dir, "output_response.txt")

            env_vars = os.environ.copy()
            env_vars["GEMINI_API_KEY"] = api_key
            env_vars["CI"] = "true"
            env_vars["TERM"] = "dumb"
            env_vars["NO_COLOR"] = "1"
            env_vars["HOME"] = temp_home_dir

            schema_enforcement = '{"luau_code_payload": "string kode luau murni"}'

            full_payload = (
                f"[SYSTEM INSTRUCTION]:\n{system_instruction}\n\n"
                f"[WAJIB OUTPUT JSON MURNI SESUAI SCHEMA BERIKUT]:\n{schema_enforcement}\n\n"
                f"[PROMPT TASK]:\n{prompt_payload}"
            )

            with open(prompt_filepath, "w", encoding="utf-8") as f:
                f.write(full_payload)

            # URUTAN MODEL: Gemini 3.1 -> 3 -> 2.5 Flash
            model_candidates = [
                "models/gemini-3.1-flash-lite-preview",
                "models/gemini-3-flash-preview",
                "models/gemini-2.5-flash",
            ]

            last_error = ""
            for model_name in model_candidates:
                try:
                    with open(prompt_filepath, "r", encoding="utf-8") as f:
                        prompt_content = f.read()

                    command = [
                        GEMINI_CLI_PATH,
                        "-m", model_name,
                        "-y",
                        "-p", "Baca seluruh data instruksi dari stdin. Keluarkan JSON murni.",
                    ]

                    process = await asyncio.create_subprocess_exec(
                        *command,
                        stdin=asyncio.subprocess.PIPE,
                        stdout=asyncio.subprocess.PIPE,
                        stderr=asyncio.subprocess.PIPE,
                        env=env_vars,
                        start_new_session=True,
                    )

                    try:
                        stdout_data, stderr_data = await asyncio.wait_for(
                            process.communicate(input=prompt_content.encode("utf-8")),
                            timeout=120.0,
                        )
                    except asyncio.TimeoutError:
                        try:
                            os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                        except (OSError, ProcessLookupError):
                            pass
                        try:
                            await asyncio.wait_for(process.communicate(), timeout=5.0)
                        except asyncio.TimeoutError:
                            pass
                        last_error = f"API Timeout 120s ({model_name})."
                        continue

                    if process.returncode != 0:
                        error_details = stderr_data.decode("utf-8", errors="ignore").strip().lower()
                        if "429" in error_details or "quota" in error_details or "exhausted" in error_details or "rate" in error_details:
                            # Aktifkan global cooldown 60 detik agar semua agent berhenti
                            await _set_global_rate_limit(60.0)
                            return False, "RATE_LIMIT_REACHED"
                        last_error = f"CLI_ERROR ({model_name}): {error_details[:300]}"
                        continue

                    raw_output = stdout_data.decode("utf-8", errors="ignore")

                    with open(output_filepath, "w", encoding="utf-8") as f:
                        f.write(raw_output)

                    # LOGIKA EKSTRAKSI JSON PRESISI
                    markdown_match = re.search(r'```(?:json)?\n(.*?)\n```', raw_output, re.DOTALL | re.IGNORECASE)

                    if markdown_match:
                        clean_str = markdown_match.group(1).strip()
                        try:
                            parsed = json.loads(clean_str, strict=False)
                            code = parsed.get("luau_code_payload", "")
                            if code:
                                return True, extract_pure_luau_code(code)
                        except Exception:
                            pass

                    # Fallback: cari batas JSON langsung
                    start_idx = raw_output.find('{')
                    end_idx = raw_output.rfind('}')
                    if start_idx != -1 and end_idx != -1 and end_idx >= start_idx:
                        clean_str = raw_output[start_idx:end_idx + 1]
                        try:
                            parsed = json.loads(clean_str, strict=False)
                            code = parsed.get("luau_code_payload", "")
                            if code:
                                return True, extract_pure_luau_code(code)
                        except Exception:
                            pass

                    last_error = f"JSON_PARSE_ERROR ({model_name}): Output rusak.\nRaw: {raw_output[:200]}..."
                    continue

                except FileNotFoundError:
                    return False, f"GEMINI_CLI_NOT_FOUND: '{GEMINI_CLI_PATH}' tidak ditemukan. Pastikan gemini-cli terinstall."
                except Exception as e:
                    last_error = f"SYSTEM_EXCEPTION ({model_name}): {str(e)}"
                    continue

            return False, last_error

        finally:
            # Bersihkan direktori sementara setelah semua percobaan selesai
            if os.path.exists(temp_home_dir):
                shutil.rmtree(temp_home_dir, ignore_errors=True)


class AutoHealerAgent:
    def __init__(self):
        self.sys_inst = (
            "Anda adalah Ahli Bedah Kode. Perbaiki kode Luau yang rusak berdasarkan pesan error "
            "dari Native Luau Compiler. JANGAN MENGHAPUS LOGIKA LAMA. JANGAN menulis ulang dari awal. "
            "HANYA perbaiki baris yang menyebabkan error. Sebelum memperbaiki, CARI tahu penyebab "
            "error ini dari dokumentasi Roblox Developer Hub dan luau-lang.org. "
            "KEMBALIKAN OUTPUT DALAM FORMAT JSON MURNI sesuai schema yang diberikan."
        )

    async def heal_code(self, broken_code: str, compiler_error: str, module_name: str, agent: dict) -> str:
        last_error_line = compiler_error.splitlines()[-1] if compiler_error else "Unknown"
        console_terminal_interface.print(
            f"[bold magenta]   [Auto-Healer] Membedah {module_name}: {last_error_line}[/bold magenta]"
        )
        safe_broken_code = extract_pure_luau_code(broken_code)
        prompt = (
            f"[COMPILER ERROR LOG]:\n{compiler_error}\n\n"
            f"[KODE LUAU RUSAK]:\n{MARKDOWN_BLOCK}lua\n{safe_broken_code}\n{MARKDOWN_BLOCK}\n\n"
            "Keluarkan JSON murni berisi 'luau_code_payload' yang sudah diperbaiki mutlak."
        )
        success, result = await execute_gemini_cli_pure(agent, self.sys_inst, prompt)
        if success and result:
            return result
        return broken_code


class OmniSynthesizerAgent:
    def __init__(self, healer_agent: AutoHealerAgent):
        self.healer_agent = healer_agent
        self.sys_inst = (
            "Anda adalah Arsitek Penyatuan Multiverse Luau. Tulis kode Luau Murni. "
            "Wajib --!strict. Fokus pada efisiensi matematika dan kinerja server. "
            "Sebelum menulis kode, gunakan pengetahuan dari dokumentasi Roblox Developer Hub, "
            "luau-lang.org, dan contoh kode di GitHub untuk memastikan API yang digunakan valid."
        )

    async def synthesize_handoff(
        self,
        agent: dict,
        target_filepath: str,
        module_name: str,
        task_description: str,
        req_keys: list,
        forb_keys: list,
        previous_error: str,
        previous_code: str,
    ) -> Tuple[bool, str, str]:
        comprehensive_prompt = (
            "[HUKUM ALAM SEMESTA GAME - MUTLAK]\n"
            "1. Game Ekstraksi Survival Bumi 1:1. Pemain statis tanpa Level/XP.\n"
            "2. Kekuatan eksklusif dari item: Generator Mana Level 1-9 (Kualitas Low memotong HP pemain).\n"
            "3. Ekologi & Fisika: Mesh Slicing (EditableMesh), SPH Blood, Voxel Terraforming.\n"
            "4. Akustik & Server: 150 Menit Timer, Anti-Combat Log (Alt+F4), Dungeon Master Possession.\n"
            "5. Kematian = 100% item hilang kecuali di Safe Container DataStore.\n\n"
        )

        ecosystem_context = await retrieve_ecosystem_context()
        if ecosystem_context:
            comprehensive_prompt += f"[REFERENSI MODUL GLOBAL UNTUK REQUIRE()]:\n{ecosystem_context}\n\n"
        comprehensive_prompt += f"[INSTRUKSI TUGAS ({module_name})]:\n{task_description}\n\n"

        if previous_error and previous_code:
            safe_code = extract_pure_luau_code(previous_code)
            comprehensive_prompt += (
                f"[CRITICAL ERROR DARI AGEN SEBELUMNYA - PERBAIKI MATEMATIS]:\n"
                f"{MARKDOWN_BLOCK}lua\n{safe_code}\n{MARKDOWN_BLOCK}\n"
                f"[ERROR LOG]:\n{previous_error}\n\n"
                "PERBAIKI KESALAHAN INI TANPA MENGUBAH FITUR YANG SUDAH BENAR!\n"
            )

        console_terminal_interface.print(
            f"[bold cyan]  [{agent['name']}] Memproses {module_name}... (Antri Sequential)[/bold cyan]"
        )
        success, result_data = await execute_gemini_cli_pure(agent, self.sys_inst, comprehensive_prompt)

        if success:
            code_attempt = result_data

            is_valid_omni, omni_msg = AbsoluteOmniValidator.execute_validation(code_attempt, req_keys, forb_keys)
            if not is_valid_omni:
                code_attempt = await self.healer_agent.heal_code(code_attempt, omni_msg, module_name, agent)
                is_valid_omni, omni_msg = AbsoluteOmniValidator.execute_validation(code_attempt, req_keys, forb_keys)
                if not is_valid_omni:
                    return False, f"Omni-Linter: {omni_msg}", code_attempt

            is_valid_ast, compile_msg = await NativeLuauCompiler.execute_native_ast_verification(code_attempt, module_name)
            if not is_valid_ast:
                code_attempt = await self.healer_agent.heal_code(code_attempt, compile_msg, module_name, agent)
                is_valid_ast, compile_msg = await NativeLuauCompiler.execute_native_ast_verification(code_attempt, module_name)
                if not is_valid_ast:
                    return False, f"Native Compiler: {compile_msg}", code_attempt

            hash_val = await save_verified_module(module_name, target_filepath, code_attempt)
            console_terminal_interface.print(
                f"[bold green]✅ [{agent['name']}] Node {module_name} Lulus. Hash: {hash_val[:8]}[/bold green]"
            )
            return True, "", code_attempt
        else:
            if "RATE_LIMIT" in result_data:
                console_terminal_interface.print(
                    f"[bold yellow][{agent['name']}] Rate limit terdeteksi. Global cooldown aktif, akan dilanjutkan...[/bold yellow]"
                )
                # Cooldown sudah diset di dalam execute_gemini_cli_pure, tidak perlu sleep lagi di sini
            return False, result_data, previous_code
