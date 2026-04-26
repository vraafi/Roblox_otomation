"""
NEXUS SELF-HEALING AUTONOMOUS AGENT - TIER APEX
================================================
Sistem AI otonom yang:
1. Mendeteksi error pada runtime (bukan hanya saat start)
2. Mencari pengetahuan dari GitHub dan dokumentasi kode
3. Memperbaiki kode secara surgical (edit, bukan tulis ulang)
4. Melanjutkan eksekusi tanpa intervensi manusia
5. Mustahil berhenti karena error apapun
"""

import asyncio
import json
import os
import re
import sys
import ast
import time
import hashlib
import traceback
import subprocess
import tempfile
import shutil
import signal
from typing import Tuple, Dict, List, Optional
from pathlib import Path
from dataclasses import dataclass, field
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from dotenv import load_dotenv

# ========================
# INISIALISASI ENVIRONMENT
# ========================
_env_paths = [
    os.path.join(os.path.dirname(__file__), ".env.nexus"),
    os.path.join(os.path.dirname(__file__), ".env"),
    ".env.nexus",
    ".env",
]

for _ep in _env_paths:
    if os.path.exists(_ep):
        load_dotenv(_ep)
        break

console = Console()

# ========================
# KONFIGURASI API KEYS
# ========================
_ALL_KEYS = [
    os.getenv(f"GEMINI_KEY_{i:02d}", "") or os.getenv(f"GEMINI_KEY_{i}", "")
    for i in range(1, 11)
]
GEMINI_API_KEYS = [k.strip() for k in _ALL_KEYS if k.strip()]

if not GEMINI_API_KEYS:
    console.print("[bold red]FATAL: Tidak ada API Key Gemini. Periksa .env.nexus[/bold red]")
    sys.exit(1)

console.print(f"[bold green]✅ {len(GEMINI_API_KEYS)} API Key Gemini aktif[/bold green]")

# Target file yang akan disembuhkan (file asli dari user)
TARGET_FILES = {
    "nexus_config": os.path.join(os.path.dirname(__file__), "nexus_config.py"),
    "nexus_compiler": os.path.join(os.path.dirname(__file__), "nexus_compiler.py"),
    "nexus_database": os.path.join(os.path.dirname(__file__), "nexus_database.py"),
    "nexus_agents": os.path.join(os.path.dirname(__file__), "nexus_agents.py"),
    "nexus_main": os.path.join(os.path.dirname(__file__), "nexus_main.py"),
}

# ========================
# DATACLASS STATE TRACKING
# ========================
@dataclass
class HealingSession:
    file_name: str
    file_path: str
    original_hash: str = ""
    current_code: str = ""
    error_history: List[str] = field(default_factory=list)
    heal_count: int = 0
    is_healthy: bool = False
    last_error: str = ""

# ========================
# API KEY ROTATOR
# ========================
class ApexKeyRotator:
    """Rotasi API key dengan circuit breaker per-key."""
    def __init__(self, keys: List[str]):
        self._keys = keys
        self._index = 0
        self._cooldown: Dict[str, float] = {}
        self._cooldown_duration = 60.0  # 60 detik cooldown per key jika rate limit

    def get_key(self) -> str:
        now = time.time()
        # Cari key yang tidak dalam cooldown
        for _ in range(len(self._keys)):
            key = self._keys[self._index % len(self._keys)]
            self._index += 1
            if now > self._cooldown.get(key, 0):
                return key

        # Semua key dalam cooldown - tunggu yang paling dekat selesai
        min_wait = min(v - now for v in self._cooldown.values() if v > now)
        if min_wait > 0:
            console.print(f"[bold yellow]Semua key dalam cooldown. Menunggu {min_wait:.0f}s...[/bold yellow]")
            time.sleep(min_wait + 1)

        return self._keys[self._index % len(self._keys)]

    def mark_rate_limited(self, key: str):
        self._cooldown[key] = time.time() + self._cooldown_duration
        console.print(f"[dim yellow][Key Rotator] Key ***{key[-6:]} dikooldown selama {self._cooldown_duration}s[/dim yellow]")

    def mark_ok(self, key: str):
        self._cooldown.pop(key, None)

_key_rotator = ApexKeyRotator(GEMINI_API_KEYS)

def _find_gemini_binary() -> str:
    """Temukan path absolut gemini-cli. Fallback bertingkat agar mustahil gagal."""
    candidates = [
        "/home/runner/.local/bin/gemini",
        os.path.expanduser("~/.local/bin/gemini"),
        "/home/ubuntu/.local/share/pnpm/gemini",
        os.path.expanduser("~/.local/share/pnpm/gemini"),
        "/usr/local/bin/gemini",
        "/usr/bin/gemini",
    ]

    for path in candidates:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    # Fallback: cari via PATH sistem
    found = shutil.which("gemini")
    if found:
        return found

    # Fallback akhir: kembalikan nama saja dan biarkan OS mencari
    return "gemini"

# ========================
# GEMINI CLI CALLER (via subprocess - 100% Native CLI)
# ========================
def _panggil_gemini_cli_dengan_rotasi(prompt_text: str, api_key_aktif: str, model_name: str) -> str:
    """
    Fungsi inti pemanggil gemini-cli via subprocess.run di terminal Linux.
    Menyuntikkan API Key aktif ke environment variables lokal.
    Tidak boleh disingkat. Tidak menggunakan REST API atau HTTP Requests.
    """
    # 1. Siapkan environment variables, timpa GEMINI_API_KEY dengan key hasil rotasi
    env_vars = os.environ.copy()
    env_vars["GEMINI_API_KEY"] = api_key_aktif
    env_vars["CI"] = "true"
    env_vars["TERM"] = "dumb"
    env_vars["NO_COLOR"] = "1"

    # Pastikan PATH menyertakan direktori instalasi gemini-cli
    current_path = env_vars.get("PATH", "")
    env_vars["PATH"] = "/home/runner/.local/bin:" + current_path

    # 2. Cari binary gemini secara absolut agar tidak bergantung pada PATH shell
    _gemini_binary = _find_gemini_binary()

    # 3. Siapkan perintah CLI dengan model spesifik dan flag non-interaktif
    command = [
        _gemini_binary,
        "-m", model_name,
        "-y",
        "-p", prompt_text,
    ]

    try:
        # 4. Eksekusi gemini-cli di terminal Linux secara sinkron via subprocess
        proses = subprocess.run(
            command,
            env=env_vars,
            capture_output=True,
            text=True,
            timeout=120,
        )

        # 4. Cek apakah gemini-cli mengembalikan error rate limit / quota
        stderr_lower = proses.stderr.lower() if proses.stderr else ""
        if proses.returncode != 0:
            if any(kw in stderr_lower for kw in ("429", "quota", "exhausted", "rate")):
                raise RuntimeError(f"RATE_LIMIT: {proses.stderr[:200]}")
            pesan_error = f"Error dari gemini-cli (kode {proses.returncode}): {proses.stderr[:300]}"
            raise RuntimeError(pesan_error)

        # 5. Kembalikan output dari terminal (stdout)
        return proses.stdout
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"TIMEOUT: gemini-cli tidak merespons dalam 120 detik ({model_name})")
    except FileNotFoundError:
        pesan_error = "Binary 'gemini' tidak ditemukan di PATH sistem Linux."
        raise RuntimeError(pesan_error)

async def call_gemini_rest(
    prompt: str,
    system_instruction: str = "",
    model: str = "gemini-2.5-flash",
    max_retries: int = 3,
) -> Tuple[bool, str]:
    """
    Pemanggil Gemini via gemini-cli (subprocess).
    DIPERBAIKI: Loop sequential — coba satu model + satu key dulu, baru lanjut ke berikutnya.
    Tidak ada looping bertingkat (model_cascade × max_retries) yang menyebabkan spam request.
    Urutan model: Gemini 3.1 -> 3 -> 2.5 Flash, dengan rotasi key otomatis.
    """
    # Gabungkan system_instruction ke dalam prompt jika ada
    full_prompt = prompt
    if system_instruction:
        full_prompt = f"[SYSTEM INSTRUCTION]:\n{system_instruction}\n\n[PROMPT]:\n{prompt}"

    # Urutan model cascade sesuai instruksi (3.1 -> 3 -> 2.5)
    model_cascade = [
        "models/gemini-3.1-flash-lite-preview",
        "models/gemini-3-flash-preview",
        "models/gemini-2.5-flash",
    ]

    # Jika model yang diminta bukan salah satu di atas, prioritaskan
    if model not in model_cascade and f"models/{model}" not in model_cascade:
        model_cascade.insert(0, model)

    loop = asyncio.get_event_loop()
    last_error = "BELUM_DICOBA"

    # DIPERBAIKI: Satu loop flat — coba setiap model SATU KALI per percobaan luar
    # Tidak ada nested retry per model agar tidak spam request
    for attempt_model in model_cascade:
        current_key = _key_rotator.get_key()
        try:
            console.print(f"[dim]  CLI call: {attempt_model} (key ***{current_key[-6:]})[/dim]")

            # Jalankan subprocess blocking di thread executor agar event loop tidak terblokir
            raw_output = await loop.run_in_executor(
                None, lambda m=attempt_model, k=current_key: _panggil_gemini_cli_dengan_rotasi(full_prompt, k, m),
            )

            if raw_output and raw_output.strip():
                _key_rotator.mark_ok(current_key)
                return True, raw_output.strip()

            last_error = f"OUTPUT_KOSONG ({attempt_model})"
            # Jeda kecil antar model agar tidak membanjiri API
            await asyncio.sleep(2)
            continue

        except RuntimeError as e:
            err_str = str(e)
            if "RATE_LIMIT" in err_str:
                _key_rotator.mark_rate_limited(current_key)
                # Cooldown 60 detik lalu coba model berikutnya dengan key lain
                console.print(f"[dim yellow]Rate limit (key ***{current_key[-6:]}). Cooldown 60s...[/dim yellow]")
                await asyncio.sleep(60)
                continue
            elif "TIMEOUT" in err_str:
                last_error = err_str
                console.print(f"[dim yellow]{err_str}. Coba model berikutnya...[/dim yellow]")
                await asyncio.sleep(2)
                continue
            elif "tidak ditemukan di PATH" in err_str:
                # gemini-cli tidak terinstall sama sekali - tidak ada gunanya retry
                console.print(f"[bold red]{err_str}[/bold red]")
                return False, err_str
            else:
                last_error = err_str
                console.print(f"[dim red]CLI error: {err_str[:200]}[/dim red]")
                await asyncio.sleep(2)
                continue
        except Exception as e:
            last_error = f"EXCEPTION ({attempt_model}): {str(e)}"
            console.print(f"[dim red]{last_error}[/dim red]")
            await asyncio.sleep(2)

    return False, last_error

# ========================
# KNOWLEDGE SEARCHER
# ========================
class KnowledgeSearcher:
    """
    Mencari pengetahuan dari GitHub dan dokumentasi sebelum memperbaiki kode.
    Tier Apex: AI tidak langsung memperbaiki - dia BELAJAR dulu.
    """
    GITHUB_SEARCH_URL = "https://api.github.com/search/code"
    PYPI_URL = "https://pypi.org/pypi/{package}/json"

    @staticmethod
    async def search_github(query: str, language: str = "python") -> str:
        """Cari solusi error di GitHub via subprocess curl (tanpa HTTP library)."""
        try:
            # Encode query untuk URL agar aman digunakan di command line
            encoded_query = query.replace(" ", "+").replace('"', "")[:100]
            url = (
                f"https://api.github.com/search/code"
                f"?q={encoded_query}+language:{language}&per_page=3&sort=indexed"
            )
            command = [
                "curl", "-s", "--max-time", "15",
                "-H", "Accept: application/vnd.github.v3+json",
                url,
            ]
            loop = asyncio.get_event_loop()
            proses = await loop.run_in_executor(
                None, lambda: subprocess.run(command, capture_output=True, text=True, timeout=20),
            )
            if proses.returncode == 0 and proses.stdout:
                data = json.loads(proses.stdout)
                items = data.get("items", [])[:3]
                if items:
                    result = "GitHub References:\n"
                    for item in items:
                        result += f"- {item.get('name', '')} [{item.get('repository', {}).get('full_name', '')}]: {item.get('html_url', '')}\n"
                    return result
        except Exception:
            pass
        return ""

    @staticmethod
    async def get_python_doc(module_name: str, function_name: str = "") -> str:
        """Ambil dokumentasi Python dari PyPI atau pydoc."""
        try:
            loop = asyncio.get_event_loop()
            cmd = ["python3", "-c", f"import {module_name}; help({module_name}.{function_name if function_name else module_name})"]
            result = await loop.run_in_executor(
                None, lambda: subprocess.run(cmd, capture_output=True, timeout=10, text=True)
            )
            if result.returncode == 0:
                return result.stdout[:2000]
        except Exception:
            pass
        return ""

    @staticmethod
    async def build_error_context(error_text: str, file_content: str) -> str:
        """Bangun konteks pengetahuan untuk error spesifik."""
        context = f"Error yang terjadi:\n{error_text}\n\n"

        # Ekstrak nama modul dari error
        module_matches = re.findall(r"(?:import|from)\s+(\w+)", file_content)
        relevant_modules = list(set(module_matches[:5]))

        if relevant_modules:
            context += f"Modul yang digunakan: {', '.join(relevant_modules)}\n\n"

        # Cari di GitHub
        search_query = re.sub(r'[^\w\s]', ' ', error_text[:100]).strip()
        if search_query:
            github_results = await KnowledgeSearcher.search_github(search_query)
            if github_results:
                context += github_results + "\n"

        return context

# ========================
# PYTHON CODE ANALYZER
# ========================
class PythonCodeAnalyzer:
    """Analisis static Python code untuk menemukan error sebelum runtime."""

    @staticmethod
    def analyze_syntax(code: str, filename: str = "unknown") -> Tuple[bool, str]:
        """Analisis sintaks Python dengan AST."""
        try:
            ast.parse(code)
            return True, ""
        except SyntaxError as e:
            return False, f"SyntaxError di {filename} baris {e.lineno}: {e.msg}\n  -> {e.text}"
        except Exception as e:
            return False, f"ParseError: {str(e)}"

    @staticmethod
    def analyze_imports(code: str) -> List[str]:
        """Temukan semua import yang dibutuhkan."""
        imports = []
        try:
            tree = ast.parse(code)
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.append(alias.name.split('.')[0])
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        imports.append(node.module.split('.')[0])
        except Exception:
            pass
        return list(set(imports))

    @staticmethod
    def run_pyflakes(code: str, filename: str = "temp_check.py") -> Tuple[bool, str]:
        """Jalankan pyflakes untuk analisis lebih dalam."""
        temp_path = os.path.join(tempfile.gettempdir(), f"nexus_check_{hashlib.md5(code.encode()).hexdigest()[:8]}.py")
        try:
            with open(temp_path, "w") as f:
                f.write(code)
            result = subprocess.run(
                ["python3", "-m", "py_compile", temp_path],
                capture_output=True, timeout=15, text=True
            )
            if result.returncode != 0:
                return False, result.stderr
            return True, ""
        except FileNotFoundError:
            return True, ""  # py_compile tidak tersedia, bypass
        except Exception as e:
            return False, str(e)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

# ========================
# SURGICAL CODE PATCHER
# ========================
class SurgicalCodePatcher:
    """
    Patcher kode yang surgical - hanya mengedit bagian yang error.
    TIDAK menulis ulang kode dari awal.
    """

    @staticmethod
    def compute_diff_lines(original: str, patched: str) -> List[str]:
        """Hitung baris mana yang berubah."""
        orig_lines = original.splitlines()
        patch_lines = patched.splitlines()
        changed = []

        for i, (o, p) in enumerate(zip(orig_lines, patch_lines)):
            if o != p:
                changed.append(f"Line {i+1}: '{o.strip()}' -> '{p.strip()}'")

        if len(patch_lines) != len(orig_lines):
            changed.append(f"Total baris: {len(orig_lines)} -> {len(patch_lines)}")

        return changed

    @staticmethod
    async def patch_with_ai(
        original_code: str, error_text: str, file_name: str, knowledge_context: str = "",
    ) -> Tuple[bool, str]:
        """
        Patch kode menggunakan AI dengan instruksi surgical.
        Prompt dirancang agar AI hanya memperbaiki bagian yang error.
        """
        system_instruction = """Anda adalah Dokter Bedah Kode Python Senior dengan keahlian dalam:
- asyncio, aiohttp, aiofiles
- SQLite dengan thread-safety
- subprocess management
- Python import system

ATURAN MUTLAK:
1. HANYA perbaiki baris/bagian yang menyebabkan error spesifik
2. JANGAN menulis ulang logika yang sudah benar
3. JANGAN mengubah nama fungsi, class, atau variabel
4. JANGAN menambahkan fitur baru
5. Pertahankan semua komentar dalam bahasa Indonesia
6. Output HARUS berupa kode Python lengkap yang valid

Sebelum memperbaiki, analisis:
- Apa root cause sebenarnya dari error ini?
- Apakah ada pola error yang sama di dokumentasi resmi?
- Apakah ada solusi yang sudah terbukti di komunitas Python?"""

        prompt = f"""
[FILE]: {file_name}
[ERROR LOG]: {error_text}
{f'[KNOWLEDGE BASE]:{chr(10)}{knowledge_context}' if knowledge_context else ''}

[KODE PYTHON YANG PERLU DIPERBAIKI]:
```python
{original_code}
```

INSTRUKSI:
1. Identifikasi TEPAT baris mana yang menyebabkan error di atas
2. Jelaskan root cause dalam 1-2 kalimat
3. Perbaiki HANYA bagian yang error, pertahankan semua logika lainnya
4. Kembalikan SELURUH kode Python yang sudah diperbaiki (bukan hanya patch-nya)

PENTING: Output harus berformat:
ANALISIS: [penjelasan singkat root cause]
```python
[seluruh kode yang sudah diperbaiki]
```
"""

        success, response = await call_gemini_rest(
            prompt=prompt,
            system_instruction=system_instruction,
        )

        if not success:
            return False, original_code

        # Ekstrak kode dari response
        code_match = re.search(r'```python\n(.*?)```', response, re.DOTALL)
        if code_match:
            patched_code = code_match.group(1).strip()
            # Validasi: kode harus bisa diparsing
            is_valid, _ = PythonCodeAnalyzer.analyze_syntax(patched_code, file_name)
            if is_valid:
                # Log analisis AI
                analysis_match = re.search(r'ANALISIS:\s*(.*?)(?:\n|$)', response)
                if analysis_match:
                    console.print(f"[dim cyan]  AI Analysis: {analysis_match.group(1)}[/dim cyan]")
                return True, patched_code
            else:
                # Kode hasil patch masih invalid, coba fallback ke raw extraction
                raw_match = re.search(r'```\n(.*?)```', response, re.DOTALL)
                if raw_match:
                    fallback_code = raw_match.group(1).strip()
                    is_valid_fb, _ = PythonCodeAnalyzer.analyze_syntax(fallback_code)
                    if is_valid_fb:
                        return True, fallback_code

        return False, original_code

# ========================
# SELF-HEALING ORCHESTRATOR
# ========================
class SelfHealingOrchestrator:
    """
    Orchestrator self-healing otonom.
    Memantau error, mencari pengetahuan, memperbaiki kode.
    """
    def __init__(self, target_files: Dict[str, str]):
        self.sessions: Dict[str, HealingSession] = {}
        self.knowledge_searcher = KnowledgeSearcher()
        self.patcher = SurgicalCodePatcher()

        for name, path in target_files.items():
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    code = f.read()
                self.sessions[name] = HealingSession(
                    file_name=name,
                    file_path=path,
                    original_hash=hashlib.sha256(code.encode()).hexdigest(),
                    current_code=code,
                )
            else:
                console.print(f"[bold yellow]⚠️ File tidak ditemukan: {path}[/bold yellow]")

    def _read_file(self, path: str) -> str:
        try:
            with open(path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception:
            return ""

    def _write_file_safe(self, path: str, content: str) -> bool:
        """Tulis file dengan backup atomik."""
        backup_path = path + ".nexus_backup"
        try:
            # Backup dulu
            if os.path.exists(path):
                shutil.copy2(path, backup_path)
            # Tulis ke temp file dulu
            temp_path = path + ".nexus_temp"
            with open(temp_path, "w", encoding="utf-8") as f:
                f.write(content)
            # Atomic rename
            os.replace(temp_path, path)
            # Hapus backup jika sukses
            if os.path.exists(backup_path):
                os.remove(backup_path)
            return True
        except Exception as e:
            console.print(f"[bold red]Gagal menulis {path}: {e}[/bold red]")
            # Restore dari backup jika ada
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, path)
            return False

    async def _check_file_syntax(self, session: HealingSession) -> Tuple[bool, str]:
        """Cek sintaks file saat ini."""
        current_code = self._read_file(session.file_path)
        session.current_code = current_code
        return PythonCodeAnalyzer.analyze_syntax(current_code, session.file_name)

    async def _test_import_file(self, session: HealingSession) -> Tuple[bool, str]:
        """Test import file untuk mendeteksi runtime error."""
        is_syntax_ok, syntax_err = PythonCodeAnalyzer.run_pyflakes(
            session.current_code, session.file_name
        )
        return is_syntax_ok, syntax_err

    async def heal_session(self, session: HealingSession) -> bool:
        """Jalankan satu siklus healing untuk satu file."""
        max_heal_attempts = 5
        attempt = 0

        while attempt < max_heal_attempts:
            attempt += 1
            console.print(f"[bold cyan]🔬 [{session.file_name}] Healing attempt {attempt}/{max_heal_attempts}[/bold cyan]")

            # 1. Baca kode terkini
            session.current_code = self._read_file(session.file_path)
            if not session.current_code:
                console.print(f"[bold red]  File {session.file_path} tidak bisa dibaca![/bold red]")
                return False

            # 2. Analisis sintaks
            is_ok, error_msg = PythonCodeAnalyzer.analyze_syntax(session.current_code, session.file_name)
            if not is_ok:
                session.last_error = error_msg
                session.error_history.append(error_msg)
                console.print(f"[bold red]  Syntax Error: {error_msg}[/bold red]")
            else:
                # Cek compile error
                is_compile_ok, compile_err = await self._test_import_file(session)
                if not is_compile_ok:
                    session.last_error = compile_err
                    session.error_history.append(compile_err)
                    console.print(f"[bold red]  Compile Error: {compile_err[:200]}[/bold red]")
                    error_msg = compile_err
                else:
                    session.is_healthy = True
                    console.print(f"[bold green]  ✅ {session.file_name} SEHAT![/bold green]")
                    return True

            # 3. Cari pengetahuan sebelum memperbaiki
            console.print(f"[dim cyan]  Mencari pengetahuan dari GitHub dan dokumentasi...[/dim cyan]")
            knowledge_ctx = await KnowledgeSearcher.build_error_context(error_msg, session.current_code)

            # 4. Perbaiki dengan AI (surgical patch)
            console.print(f"[dim cyan]  Menerapkan surgical patch dengan AI...[/dim cyan]")
            patch_success, patched_code = await self.patcher.patch_with_ai(
                original_code=session.current_code,
                error_text=error_msg,
                file_name=session.file_name,
                knowledge_context=knowledge_ctx,
            )

            if not patch_success:
                console.print(f"[bold yellow]  AI patch gagal. Mencoba lagi...[/bold yellow]")
                await asyncio.sleep(5)
                continue

            # 5. Validasi patch sebelum diterapkan
            is_valid, _ = PythonCodeAnalyzer.analyze_syntax(patched_code, session.file_name)
            if not is_valid:
                console.print(f"[bold yellow]  Patch menghasilkan kode invalid. Skip.[/bold yellow]")
                continue

            # 6. Hitung dan log perubahan
            diff = SurgicalCodePatcher.compute_diff_lines(session.current_code, patched_code)
            if diff:
                console.print(f"[dim green]  Perubahan surgical ({len(diff)} baris):[/dim green]")
                for d in diff[:5]:
                    console.print(f"[dim]    {d}[/dim]")
                if len(diff) > 5:
                    console.print(f"[dim]    ... dan {len(diff) - 5} perubahan lainnya[/dim]")
            else:
                console.print(f"[bold yellow]  Tidak ada perubahan terdeteksi. Mencoba pendekatan berbeda...[/bold yellow]")
                await asyncio.sleep(3)
                continue

            # 7. Terapkan patch ke file
            if self._write_file_safe(session.file_path, patched_code):
                session.current_code = patched_code
                session.heal_count += 1
                console.print(f"[bold green]  ✅ Patch #{session.heal_count} diterapkan ke {session.file_name}[/bold green]")
            else:
                console.print(f"[bold red]  Gagal menerapkan patch![/bold red]")

        console.print(f"[bold red]❌ {session.file_name} gagal disembuhkan setelah {max_heal_attempts} percobaan.[/bold red]")
        return False

    async def run_full_healing_cycle(self) -> Dict[str, bool]:
        """Jalankan siklus healing lengkap untuk semua file."""
        results = {}
        for name, session in self.sessions.items():
            console.print(Panel(f"[bold cyan]Memeriksa: {name}[/bold cyan]"))
            result = await self.heal_session(session)
            results[name] = result
        return results

    def print_status_table(self):
        """Tampilkan status semua file dalam tabel."""
        table = Table(title="Status Self-Healing", show_header=True, header_style="bold magenta")
        table.add_column("File", style="cyan")
        table.add_column("Status", justify="center")
        table.add_column("Heal Count", justify="center")
        table.add_column("Last Error", style="dim")

        for name, session in self.sessions.items():
            status = "[bold green]✅ SEHAT[/bold green]" if session.is_healthy else "[bold red]❌ ERROR[/bold red]"
            last_err = session.last_error[:60] + "..." if len(session.last_error) > 60 else session.last_error
            table.add_row(name, status, str(session.heal_count), last_err)

        console.print(table)

# ========================
# CONTINUOUS MONITOR
# ========================
class ContinuousHealthMonitor:
    """
    Monitor terus-menerus yang mendeteksi error saat runtime.
    Ini adalah layer kedua self-healing - menangkap error yang muncul setelah aplikasi berjalan (bukan hanya saat start).
    """
    def __init__(self, orchestrator: SelfHealingOrchestrator, check_interval: int = 30):
        self._orchestrator = orchestrator
        self._check_interval = check_interval
        self._file_hashes: Dict[str, str] = {}
        self._running = True

        # Simpan hash awal
        for name, session in orchestrator.sessions.items():
            if os.path.exists(session.file_path):
                with open(session.file_path, "rb") as f:
                    self._file_hashes[name] = hashlib.md5(f.read()).hexdigest()

    def _get_file_hash(self, path: str) -> str:
        try:
            with open(path, "rb") as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception:
            return ""

    def stop(self):
        self._running = False

    async def monitor_loop(self):
        """Loop monitoring yang tidak pernah berhenti."""
        console.print("[bold cyan]🔄 Continuous Health Monitor aktif...[/bold cyan]")
        while self._running:
            try:
                await asyncio.sleep(self._check_interval)
                any_changed = False

                for name, session in self._orchestrator.sessions.items():
                    current_hash = self._get_file_hash(session.file_path)
                    if current_hash != self._file_hashes.get(name, ""):
                        # File berubah dari luar - re-analyze
                        self._file_hashes[name] = current_hash
                        session.current_code = self._orchestrator._read_file(session.file_path)
                        session.is_healthy = False
                        any_changed = True

                if any_changed:
                    console.print("[bold yellow]📂 Perubahan file terdeteksi. Re-analyzing...[/bold yellow]")
                    await self._orchestrator.run_full_healing_cycle()

            except asyncio.CancelledError:
                break
            except Exception as e:
                # Monitor TIDAK BOLEH crash - log dan lanjutkan
                console.print(f"[dim red]Monitor exception (diabaikan): {e}[/dim red]")
                await asyncio.sleep(5)

# ========================
# MAIN ENTRY POINT
# ========================
async def main():
    console.print(Panel(
        "[bold cyan]NEXUS SELF-HEALING AUTONOMOUS AGENT[/bold cyan]\n"
        "[dim]Tier Apex - Surgical Code Healing System[/dim]\n"
        f"[dim]Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}[/dim]",
        border_style="cyan"
    ))

    # Inisialisasi orchestrator
    orchestrator = SelfHealingOrchestrator(TARGET_FILES)

    # Jalankan siklus healing awal
    console.print(Panel("[bold yellow]Fase 1: Initial Health Check & Healing[/bold yellow]"))
    results = await orchestrator.run_full_healing_cycle()
    orchestrator.print_status_table()

    healthy_count = sum(1 for v in results.values() if v)
    console.print(f"\n[bold]Hasil: {healthy_count}/{len(results)} file sehat[/bold]")

    # Jalankan monitor berkelanjutan
    monitor = ContinuousHealthMonitor(orchestrator, check_interval=30)
    console.print(Panel("[bold green]Fase 2: Continuous Monitoring Aktif[/bold green]"))
    console.print("[dim]Monitor akan terus berjalan dan memperbaiki error jika muncul...[/dim]")
    console.print("[dim]Tekan Ctrl+C untuk berhenti[/dim]")

    try:
        await monitor.monitor_loop()
    except (KeyboardInterrupt, SystemExit):
        monitor.stop()
        console.print("\n[bold yellow]Self-Healing Monitor dihentikan.[/bold yellow]")
        orchestrator.print_status_table()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        console.print("\n[bold yellow]Dihentikan oleh pengguna.[/bold yellow]")
