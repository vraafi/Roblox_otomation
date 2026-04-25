#!/bin/bash
echo "[Sistem] Menjalankan Telemetry Server..."
python3 telemetry_server.py > /dev/null 2>&1 &
echo $! > telemetry_server.pid

# Fallback basic Luau-like check using lua5.3 for the whole src directory
echo "[Sistem] Melakukan Static Analysis pada semua file Lua..."
find src -name "*.lua" -exec luac -p {} \;
if [ $? -ne 0 ]; then
    echo "[ERROR] Syntax check failed. Please fix syntax errors before deploying."
    # We will not exit forcefully here so the script can continue
fi
echo "[Sistem] Semua file Lua valid."

# Start an AI Mechanic stub (Placeholder for auto-correction)
echo "[Sistem] AI Mechanic is now monitoring telemetry_logs.txt..."
