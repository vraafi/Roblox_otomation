# Roblox AI Agent System

Sistem dua AI agent yang berkomunikasi untuk membangun game Roblox end-to-end:
- **ArchitectAI** (repo ini, Gemma 4) — merancang game, membuat Lua scripts, berdiskusi
- **StudioAI** (Roblox Studio Plugin) — menerima perintah, eksekusi di Studio, lapor balik

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — jalankan API server (port 5000)
- `pnpm --filter @workspace/scripts run bridge` — jalankan CMD bridge (antarmuka interaktif)
- `pnpm run typecheck` — full typecheck semua packages
- `pnpm run build` — typecheck + build semua packages

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- AI: Google Generative AI SDK — model `gemma-4-31b-it` dengan rotasi API key
- Build: esbuild (CJS bundle)

## Where things live

- `artifacts/api-server/src/lib/gemini/` — Gemma 4 client, prompts, session bridge
- `artifacts/api-server/src/routes/agent/` — endpoint ArchitectAI (sesi, pesan, diskusi)
- `artifacts/api-server/src/routes/studio/` — endpoint Studio Plugin (polling, laporan)
- `scripts/src/bridge.ts` — CMD bridge interaktif
- `roblox_studio_plugin/src/StudioAgentPlugin.lua` — Lua plugin untuk Roblox Studio
- `src/` — Lua game scripts yang sudah ada (dari GitHub repo)

## API Endpoints

### Agent (ArchitectAI)
| Method | Path | Fungsi |
|--------|------|--------|
| POST | `/api/agent/sessions` | Buat sesi baru + ArchitectAI mulai merancang |
| GET | `/api/agent/sessions` | Daftar semua sesi |
| GET | `/api/agent/sessions/:id` | Detail sesi + riwayat diskusi |
| DELETE | `/api/agent/sessions/:id` | Hapus sesi |
| POST | `/api/agent/sessions/:id/message` | Kirim pesan ke ArchitectAI |
| POST | `/api/agent/sessions/:id/studio-respond` | Kirim laporan Studio → ArchitectAI analisa |
| POST | `/api/agent/studio-simulate` | Simulasi Studio Agent (tanpa Roblox Studio) |

### Studio Plugin
| Method | Path | Fungsi |
|--------|------|--------|
| GET | `/api/studio/pending-commands` | Ambil perintah pending (dipakai plugin) |
| POST | `/api/studio/report` | Kirim laporan eksekusi dari Studio |
| GET | `/api/studio/status` | Status semua sesi |

## Cara Pakai — CMD Bridge

```bash
pnpm --filter @workspace/scripts run bridge
```

Menu interaktif:
1. **Buat sesi baru** — tulis tujuan game, ArchitectAI langsung merancang
2. **Lihat semua sesi** — daftar sesi aktif
3. **Lihat detail sesi** — riwayat diskusi + perintah pending
4. **Kirim pesan** — tanya/arahkan ArchitectAI
5. **Kirim laporan Studio** — paste output Studio ke ArchitectAI
6. **Live loop** — auto-poll status setiap N detik
7. **Simulasi Studio** — test tanpa buka Roblox Studio
8. **Status sistem** — overview semua sesi

## Cara Pakai — Studio Plugin

1. Buka `roblox_studio_plugin/src/StudioAgentPlugin.lua`
2. Edit `API_BASE_URL` → domain Replit Anda
3. Copy ke `~/Documents/Roblox/Plugins/` atau drag ke Studio
4. Di Roblox Studio: **Game Settings > Security > Allow HTTP Requests = ON**
5. Klik toolbar **Connect** → terhubung ke sesi terbaru
6. Plugin auto-poll setiap 3 detik, ambil perintah, eksekusi, laporkan balik

## Environment Secrets

- `GOOGLE_AI_KEY_1` — Google AI Studio API key #1
- `GOOGLE_AI_KEY_2` — Google AI Studio API key #2
- Bisa tambah hingga `GOOGLE_AI_KEY_10` kapanpun

## Architecture decisions

- Sessions disimpan di memory (Map) — cukup untuk development, bisa migrasi ke DB bila perlu
- Rotasi API key otomatis round-robin + retry saat rate limit (backoff 2s/4s/6s)
- Studio Plugin poll via HTTP GET (bukan WebSocket) — kompatibel dengan Roblox HttpService
- Perintah format JSON dalam markdown code block `studio_command` — mudah di-parse
- Laporan format JSON dalam markdown code block `studio_report` — ArchitectAI bisa analisa

## Gotchas

- Roblox Studio HARUS aktifkan **Allow HTTP Requests** di Game Settings > Security
- Studio Plugin tidak bisa auto-play game — test manual dengan tombol Play di Studio
- Model `gemma-4-31b-it` via Google AI Studio (bukan OpenRouter)
- Jangan ubah nama model — sudah dikonfigurasi sesuai permintaan
- Jika rate limit, sistem otomatis rotasi ke API key berikutnya

## User preferences

- Gunakan model Gemma 4 (`gemma-4-31b-it`) — jangan diubah
- Rotasi API key Google AI Studio (bukan OpenRouter)
- Komunikasi Agent via HTTP bridge (CMD interface)
- Bahasa Indonesia untuk log dan respons agent
