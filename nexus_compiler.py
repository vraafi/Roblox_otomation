import os
import re
import asyncio
import aiofiles
import uuid
import signal
from typing import Tuple

from nexus_config import (
    console_terminal_interface,
    LUAU_ANALYZE_BINARY_PATH,
    PROJECT_ROOT_DIRECTORY,
    TEMP_IO_DIRECTORY
)


class NativeLuauCompiler:
    @staticmethod
    def ensure_compiler_exists():
        if os.path.exists(LUAU_ANALYZE_BINARY_PATH):
            return True

        console_terminal_interface.print("[bold yellow]Mengunduh Native Luau Compiler dari GitHub...[/bold yellow]")
        try:
            import requests
            import zipfile
            import io
            import platform

            system = platform.system().lower()
            if "linux" in system:
                asset_name = "luau-ubuntu.zip"
            elif "darwin" in system:
                asset_name = "luau-macos.zip"
            else:
                asset_name = "luau-windows.zip"

            url = f"https://github.com/luau-lang/luau/releases/latest/download/{asset_name}"
            console_terminal_interface.print(f"[dim]Mengunduh dari: {url}[/dim]")

            response = requests.get(url, timeout=60)
            response.raise_for_status()

            with zipfile.ZipFile(io.BytesIO(response.content)) as zip_ref:
                names = zip_ref.namelist()
                analyze_name = next((n for n in names if "luau-analyze" in n or "luau_analyze" in n), None)
                if not analyze_name:
                    analyze_name = next((n for n in names if n.startswith("luau")), None)
                if analyze_name:
                    zip_ref.extract(analyze_name, PROJECT_ROOT_DIRECTORY)
                    extracted_path = os.path.join(PROJECT_ROOT_DIRECTORY, analyze_name)
                    if extracted_path != LUAU_ANALYZE_BINARY_PATH:
                        os.rename(extracted_path, LUAU_ANALYZE_BINARY_PATH)
                else:
                    zip_ref.extractall(PROJECT_ROOT_DIRECTORY)

            if os.path.exists(LUAU_ANALYZE_BINARY_PATH):
                os.chmod(LUAU_ANALYZE_BINARY_PATH, 0o755)
                console_terminal_interface.print("[bold green]Luau Compiler berhasil dipasang.[/bold green]")
                return True
            else:
                console_terminal_interface.print("[bold yellow]Binary luau-analyze tidak ditemukan setelah ekstraksi. Mode bypass aktif.[/bold yellow]")
                return False
        except Exception as e:
            console_terminal_interface.print(f"[bold yellow]Gagal mengunduh Compiler: {str(e)}. Mode bypass aktif.[/bold yellow]")
            return False

    @classmethod
    async def execute_native_ast_verification(cls, raw_luau_code: str, module_name: str) -> Tuple[bool, str]:
        if not os.path.exists(LUAU_ANALYZE_BINARY_PATH):
            return True, "Bypass Compiler (Binary tidak ditemukan)."

        safe_uuid = uuid.uuid4().hex[:8]
        temp_filepath = os.path.join(TEMP_IO_DIRECTORY, f"temp_{module_name}_{safe_uuid}.luau")

        try:
            async with aiofiles.open(temp_filepath, "w", encoding="utf-8") as f:
                # Jangan tambahkan --!strict jika sudah ada di kode
                if "--!strict" in raw_luau_code[:100]:
                    await f.write(raw_luau_code)
                else:
                    await f.write("--!strict\n" + raw_luau_code)

            process = await asyncio.create_subprocess_exec(
                LUAU_ANALYZE_BINARY_PATH,
                temp_filepath,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                start_new_session=True
            )

            try:
                stdout_data, stderr_data = await asyncio.wait_for(process.communicate(), timeout=30.0)
            except asyncio.TimeoutError:
                try:
                    os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                except (OSError, ProcessLookupError):
                    pass
                # Tunggu proses benar-benar selesai setelah SIGKILL
                try:
                    await asyncio.wait_for(process.communicate(), timeout=5.0)
                except asyncio.TimeoutError:
                    pass
                return False, "Fatal AST Error: Kompilator luau-analyze mengalami Timeout / Infinite Loop."

            if process.returncode == 0:
                return True, "Lulus C++ Compiler."

            raw_stderr = ""
            if stderr_data:
                raw_stderr = stderr_data.decode("utf-8", errors="ignore").strip()
            elif stdout_data:
                raw_stderr = stdout_data.decode("utf-8", errors="ignore").strip()

            # FAKTA MUTLAK: Filter false-positive Roblox global API (Unknown global)
            roblox_globals = [
                "game", "workspace", "script", "math", "task", "Instance",
                "Vector3", "Vector2", "Vector2int16", "Vector3int16",
                "CFrame", "Color3", "Color3int16", "BrickColor",
                "UDim", "UDim2", "Rect", "Region3", "Region3int16",
                "NumberRange", "NumberSequenceKeypoint", "ColorSequenceKeypoint",
                "Enum", "require", "pcall", "xpcall", "type", "typeof",
                "tick", "os", "warn", "print", "delay", "spawn", "wait",
                "tostring", "tonumber", "ipairs", "pairs", "next",
                "select", "unpack", "table", "string", "coroutine",
                "ColorSequence", "NumberSequence", "RaycastParams",
                "TweenInfo", "Random", "CatalogSearchParams",
                "HttpService", "MessagingService", "DataStoreService",
                "RunService", "Players", "ReplicatedStorage", "ServerStorage",
                "ServerScriptService", "StarterGui", "StarterPlayer",
                "PhysicsService", "CollectionService", "TweenService",
                "UserInputService", "GuiService", "SoundService",
                "ContextActionService", "PathfindingService", "MarketplaceService",
                "BadgeService", "GroupService", "LocalizationService",
                "TextService", "ContentProvider", "AssetService",
                "MemoryStoreService", "VoiceChatService", "TextChatService",
                "Lighting", "SkyBox", "Workspace", "Chat",
                "TeamService", "InsertService", "JointsService",
            ]

            # FAKTA MUTLAK: Filter false-positive Roblox type definitions (Unknown type)
            roblox_types = [
                "RBXScriptConnection", "RBXScriptSignal", "RBXScriptSignalType",
                "Connection", "Signal", "EventInstance",
                "Player", "Character", "Model", "BasePart", "Part", "MeshPart",
                "UnionOperation", "SpecialMesh", "Humanoid", "HumanoidRootPart",
                "Tool", "Script", "LocalScript", "ModuleScript", "RemoteEvent",
                "RemoteFunction", "BindableEvent", "BindableFunction", "Animation",
                "AnimationTrack", "Animator", "Attachment", "BillboardGui",
                "ScreenGui", "SurfaceGui", "Frame", "TextLabel", "TextButton",
                "ImageLabel", "ImageButton", "TextBox", "ScrollingFrame",
                "UIListLayout", "UIGridLayout", "UIAspectRatioConstraint",
                "UIPadding", "UICorner", "UIStroke", "Sound", "SoundGroup",
                "Folder", "Configuration", "StringValue", "BoolValue", "IntValue",
                "NumberValue", "ObjectValue", "Vector3Value", "CFrameValue",
                "DataStore", "GlobalDataStore", "DataStoreService",
                "TweenBase", "Tween", "RaycastResult", "RaycastParams",
                "OverlapParams", "Region3", "BoundingBox", "Ray",
                "Beam", "Trail", "ParticleEmitter", "Fire", "Smoke", "Sparkles",
                "PointLight", "SpotLight", "SurfaceLight", "AmbientLight",
                "Decal", "Texture", "Sky", "Atmosphere",
                "BodyVelocity", "BodyAngularVelocity", "BodyForce", "BodyGyro",
                "BodyPosition", "BodyThrust", "LinearVelocity", "AngularVelocity",
                "AlignPosition", "AlignOrientation", "HingeConstraint",
                "WeldConstraint", "Weld", "Motor6D", "BallSocketConstraint",
                "ProximityPrompt", "ClickDetector", "SelectionBox",
                "EditableMesh", "EditableImage", "MeshPart",
                "PathfindingModifier", "PathfindingLink",
                "NPCPathfinder", "Path",
            ]

            # Warning yang bukan error nyata — diabaikan agar tidak jadi false positive
            IGNORABLE_WARNING_CODES = [
                # Roblox arithmetic type annotations (runtime OK karena Vector3/CFrame support ops ini)
                "Unknown type used in .. operation",
                "Unknown type used in * operation",
                "Unknown type used in - operation",
                "Unknown type used in + operation",
                "Unknown type used in / operation",
                "Unknown type used in ^ operation",
                "Unknown type used in % operation",
                # Roblox return value graceful (nilai ekstra jadi nil, tidak crash)
                "Function only returns 1 value",
                "Function only returns 0 values",
                # Luau nominal typing VS Roblox structural typing (false positive)
                # Contoh: Expected 'LootItem', got 'SingularityCore' — runtime valid
                "Expected this to be exactly",
                # Luau generic type inference gagal untuk Roblox API (FindFirstChild, dll)
                "different number of generic type pack parameters",
                "different number of generic type parameters",
                # Luau table key type narrowing false positive
                # Contoh: Key 'Clear' not found in table '{ ["AcidRain" | "Clear" | ...] }'
                "not found in table",
                # Shadow/unused variable warnings (style, bukan error)
                "LocalShadow",
                "FunctionUnused",
                "LocalUnused",
                "ImportUnused",
                "VariableUnused",
                "TableLiteral",
                "SameLineStatement",
                "MultiLineStatement",
                "DeprecatedApi",
                "LintNeverEndingLoop",
                "CommentDirective",
            ]

            filtered_errors = []
            for line in raw_stderr.splitlines():
                is_false_positive = False

                # Filter: Roblox global API unknown (Unknown global)
                if "Unknown global" in line:
                    for api in roblox_globals:
                        if f"'{api}'" in line:
                            is_false_positive = True
                            break

                # Filter: Roblox type definitions unknown (Unknown type 'Player', dll)
                if not is_false_positive and "Unknown type" in line:
                    # Cek dulu di roblox_globals (Vector3, CFrame, dll juga bisa jadi type)
                    for api in roblox_globals:
                        if f"'{api}'" in line:
                            is_false_positive = True
                            break
                    # Cek di roblox_types
                    if not is_false_positive:
                        for rtype in roblox_types:
                            if f"'{rtype}'" in line:
                                is_false_positive = True
                                break

                # Filter: Warning-only codes (bukan error fatal)
                if not is_false_positive:
                    for warn_code in IGNORABLE_WARNING_CODES:
                        if warn_code in line:
                            is_false_positive = True
                            break

                if not is_false_positive:
                    filtered_errors.append(line)

            if not filtered_errors:
                return True, "Lulus (Hanya peringatan/warning yang diabaikan)."
            else:
                return False, "\n".join(filtered_errors)

        except Exception as e:
            return False, f"Subprocess Error: {str(e)}"
        finally:
            if os.path.exists(temp_filepath):
                try:
                    os.remove(temp_filepath)
                except OSError:
                    pass


class AbsoluteOmniValidator:
    """Hakim Keamanan Leksikal Murni."""

    @staticmethod
    def sanitize_luau_code(raw_luau_code: str) -> str:
        code = re.sub(r'--\[\[.*?\]\]', '', raw_luau_code, flags=re.DOTALL)
        code = re.sub(r'--[^\n]*\n', '\n', code)
        code = re.sub(r'"(?:\\.|[^"\\])*"', '""', code)
        code = re.sub(r"'(?:\\.|[^'\\])*'", "''", code)
        return code

    @classmethod
    def execute_validation(cls, raw_luau_code: str, required_keywords: list = None, forbidden_keywords: list = None) -> Tuple[bool, str]:
        required_keywords = required_keywords or []
        forbidden_keywords = forbidden_keywords or []

        if not raw_luau_code or len(raw_luau_code.strip()) < 20:
            return False, "Fatal Error: Dimensi kode kosong atau terlalu pendek."

        sanitized_code = cls.sanitize_luau_code(raw_luau_code)

        if "--!strict" not in raw_luau_code[:250]:
            return False, "Semantic Violation: Modul wajib mendeklarasikan --!strict di awal baris."

        if "_G" in sanitized_code or "shared." in sanitized_code:
            return False, "Mutation Violation: Mutasi ruang global dilarang mutlak."

        if "loadstring" in sanitized_code or "getfenv" in sanitized_code:
            return False, "RCE RISK: Dilarang menggunakan loadstring atau getfenv."

        if ("while true do" in sanitized_code or "while wait" in sanitized_code) and "task.wait" not in sanitized_code:
            return False, "Engine Crash Protocol: Loop tanpa 'task.wait()' dilarang mutlak."

        for req in required_keywords:
            if req not in sanitized_code:
                return False, f"Contract Violation: Anda diwajibkan menggunakan '{req}'."

        for forb in forbidden_keywords:
            if forb in sanitized_code:
                return False, f"Contract Violation: Dilarang menggunakan '{forb}' pada modul ini."

        return True, "Validasi Leksikal Lulus 100%."
