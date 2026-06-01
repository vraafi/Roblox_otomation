# Roblox Studio Agent Plugin

Plugin ini menghubungkan Roblox Studio dengan ArchitectAI di repo ini.

## Instalasi

1. Buka Roblox Studio
2. Klik menu **Plugins** > **Plugin Folder**
3. Copy file `src/StudioAgentPlugin.lua` ke folder tersebut sebagai `.lua`
   - Atau buka **Plugins** > **Manage Plugins** > drag & drop file
4. Restart Roblox Studio

## Konfigurasi

Edit baris ini di `StudioAgentPlugin.lua`:
```lua
API_BASE_URL = "https://YOUR_REPLIT_DOMAIN/api",
```
Ganti `YOUR_REPLIT_DOMAIN` dengan domain Replit Anda (lihat di tab preview).

## Aktifkan HTTP Requests

Di Roblox Studio:
1. **Game Settings** > **Security**
2. Aktifkan **Allow HTTP Requests**

## Cara Pakai

1. Jalankan CMD bridge dulu: `node dist/bridge.mjs` (lihat bagian CMD Bridge)
2. Atau pakai API langsung via curl/Postman
3. Di Studio, klik toolbar **Connect** untuk terhubung ke sesi terbaru
4. Klik **Poll Commands** untuk ambil dan eksekusi perintah
5. Auto-poll berjalan setiap 3 detik secara otomatis

## Toolbar Buttons

- **Connect** — Ambil sesi aktif terbaru dari API
- **Poll Commands** — Ambil & eksekusi perintah dari ArchitectAI sekarang
- **Status** — Lihat jumlah sesi & status koneksi
