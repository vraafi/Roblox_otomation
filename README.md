# NEXUS TIER ABSOLUTE APEX
### Self-Healing Autonomous Roblox Game AI Agent

Sistem AI otonom yang secara otomatis menghasilkan, memvalidasi, dan menyembuhkan kode Lua untuk game Roblox menggunakan Google Gemini API.

## Fitur Utama

- **Sequential Queue AI** — Agent antri satu per satu, tidak ada spam request paralel
- **10 Agent Pool (Round-Robin)** — Rotasi otomatis antar 10 API key Gemini
- **Global Rate Limit Cooldown** — Jika satu agent kena rate limit, semua berhenti 60 detik agar quota tidak habis
- **Auto-Healer** — Kode yang error otomatis diperbaiki secara surgical oleh AI
- **Native Luau Compiler** — Validasi kode menggunakan `luau-analyze` binary resmi
- **Self-Healing Python** — `nexus_healer.py` memantau dan memperbaiki file Python itu sendiri jika ada error
- **Roblox Open Cloud Deploy** — Auto-publish ke Roblox setelah build selesai
- **Telegram Observability** — Notifikasi real-time status deployment ke Telegram

## Arsitektur

```
nexus_main.py          — Orchestrator utama (264 tasks, 50 evolution cycles)
nexus_agents.py        — AI agent executor + Sequential Queue Semaphore
nexus_compiler.py      — Native Luau compiler + false-positive filter
nexus_database.py      — SQLite WAL database untuk verified modules
nexus_config.py        — Konfigurasi, API key pool, path detection
nexus_healer.py        — Self-healing monitor untuk file Python
start.sh               — Startup script (healer + orchestrator)
```

## Game yang Dibangun

Fantasy Extraction Survival game (mirip Arena Breakout / Dark and Darker) dengan:
- 100 monster unik per bioma
- 100 item loot dengan sistem Tetris inventory
- 10 bioma ekstrem (Banjir, Gunung, Hutan, dll)
- Sistem senjata modern + fantasy
- Lobby pesawat luar angkasa
- Sistem cuaca & bencana alam

## Persyaratan

- Python 3.11+
- Node.js 20+ (untuk Gemini CLI)
- `pip install rich python-dotenv aiohttp aiofiles requests`
- `npm install -g @google/gemini-cli`
- Rojo (untuk build .rbxl)

## Konfigurasi

Buat file `.env.nexus` di direktori yang sama (JANGAN upload ke GitHub):

```
GEMINI_KEY_01=your_key_here
...
GEMINI_KEY_10=your_key_here
ROBLOX_UNIVERSE_ID=...
ROBLOX_PLACE_ID=...
ROBLOX_OPEN_CLOUD_API_KEY=...
TELEGRAM_CHAT_ID=@your_channel
TELEGRAM_BOT_TOKEN=...
```

## Cara Jalankan

```bash
bash start.sh
```

## Perbaikan Logika (Changelog)

### v2.0 — Sequential Queue Fix
- `asyncio.Semaphore(1)` → agent benar-benar antri 1 per 1
- Global Rate Limit Cooldown → semua agent berhenti saat quota habis
- Filter false-positive Luau compiler (FunctionUnused, SameLineStatement, dll)
- Filter Unknown type Roblox (Player, Model, Humanoid, dll)
- Fix bug: `start.sh` memanggil file yang salah (`nexus_healing_agent.py`)
- Fix duplikat `--!strict` di compiler
