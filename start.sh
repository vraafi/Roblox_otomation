#!/bin/bash

# Fungsi untuk membersihkan (kill) proses background saat script dihentikan (Ctrl+C)
cleanup() {
    # Hapus trap agar tidak terjadi loop saat exit
    trap - SIGINT SIGTERM SIGHUP EXIT
    echo -e "\n[Sistem] Mematikan seluruh proses Nexus..."
    # Mematikan proses Healer yang berjalan di background
    kill $HEALER_PID 2>/dev/null
    exit 0
}

# Tangkap sinyal (Ctrl+C), kill normal, tmux pane close (SIGHUP), dan program selesai (EXIT)
trap cleanup SIGINT SIGTERM SIGHUP EXIT

echo "[Sistem] Menjalankan Nexus Healing Agent di background (Output diarahkan ke nexus_healer.log)..."
# Tanda '&' di akhir perintah membuat proses ini berjalan di latar belakang (background)
# Output diarahkan ke log agar teks tidak bertabrakan di terminal dengan nexus_main.py
python3 nexus_healer.py > nexus_healer.log 2>&1 &
# Simpan Process ID (PID) dari Healer agar bisa dimatikan nanti
HEALER_PID=$!

# Beri jeda 2 detik agar Healer siap sebelum Main Orchestrator berjalan
sleep 2

echo "[Sistem] Menjalankan Nexus Main Orchestrator di foreground..."
# Menjalankan program utama di depan (foreground) sehingga Anda bisa melihat outputnya
python3 nexus_main.py

# Jika nexus_main.py selesai atau berhenti secara normal, otomatis matikan Healer-nya juga
cleanup
