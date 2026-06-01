#!/usr/bin/env node
/**
 * CMD Bridge — Roblox AI Agent System
 *
 * Jalankan: pnpm --filter @workspace/scripts run bridge
 *
 * Ini adalah antarmuka CMD untuk:
 * 1. Membuat sesi baru (ArchitectAI merancang game)
 * 2. Melihat daftar sesi aktif
 * 3. Melihat perintah yang menunggu eksekusi di Studio
 * 4. Mengirim laporan dari Studio ke ArchitectAI
 * 5. Melanjutkan diskusi antar agent
 */

import readline from "readline";

const API_BASE =
  process.env.API_URL || "http://localhost:80/api";

const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  cyan: "\x1b[36m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  magenta: "\x1b[35m",
  blue: "\x1b[34m",
  gray: "\x1b[90m",
};

function c(color: keyof typeof colors, text: string) {
  return colors[color] + text + colors.reset;
}

async function apiGet(path: string) {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
  return res.json();
}

async function apiPost(path: string, body: unknown) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
  return res.json();
}

function printHeader() {
  console.clear();
  console.log(c("cyan", "╔════════════════════════════════════════════════════╗"));
  console.log(c("cyan", "║") + c("bright", "     🎮 ROBLOX AI AGENT BRIDGE — CMD Interface     ") + c("cyan", "║"));
  console.log(c("cyan", "║") + c("gray", "  ArchitectAI (Gemma 4) ↔ StudioAI (Roblox Studio) ") + c("cyan", "║"));
  console.log(c("cyan", "╚════════════════════════════════════════════════════╝"));
  console.log();
}

function printMenu() {
  console.log(c("bright", "  MENU:"));
  console.log(c("green",  "  [1]") + " Buat sesi baru (mulai rancang game)");
  console.log(c("green",  "  [2]") + " Lihat semua sesi");
  console.log(c("green",  "  [3]") + " Lihat detail sesi & perintah pending");
  console.log(c("green",  "  [4]") + " Kirim pesan ke ArchitectAI");
  console.log(c("green",  "  [5]") + " Kirim laporan Studio ke ArchitectAI");
  console.log(c("green",  "  [6]") + " Auto-loop: poll & forward ke Studio [LIVE MODE]");
  console.log(c("green",  "  [7]") + " Simulasi Studio Agent (tanpa Roblox Studio)");
  console.log(c("green",  "  [8]") + " Status sistem");
  console.log(c("yellow", "  [0]") + " Keluar");
  console.log();
}

function printSeparator() {
  console.log(c("gray", "  ─────────────────────────────────────────────────"));
}

function formatRole(role: string) {
  switch (role) {
    case "architect": return c("cyan", "[ArchitectAI]");
    case "studio":    return c("magenta", "[StudioAI]");
    case "user":      return c("green", "[User]");
    default:          return c("gray", `[${role}]`);
  }
}

function printMessage(msg: { role: string; content: string; timestamp: string; commands?: unknown[] }) {
  console.log();
  console.log(`  ${formatRole(msg.role)} ${c("gray", new Date(msg.timestamp).toLocaleTimeString())}`);
  const lines = msg.content.split("\n");
  for (const line of lines.slice(0, 30)) {
    console.log(c("reset", "  " + line));
  }
  if (lines.length > 30) {
    console.log(c("gray", `  ... (${lines.length - 30} baris tersembunyi)`));
  }
  if (msg.commands && (msg.commands as unknown[]).length > 0) {
    console.log(c("yellow", `  → ${(msg.commands as unknown[]).length} perintah untuk Studio`));
  }
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(prompt: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(c("yellow", "  " + prompt + " "), resolve);
  });
}

async function createSession() {
  console.log();
  console.log(c("cyan", "  📋 BUAT SESI BARU"));
  printSeparator();
  console.log(c("gray", "  Contoh: 'Buat sistem crafting untuk game ekstraksi fantasy'"));
  console.log(c("gray", "          'Tambahkan sistem quest dan reward'"));
  console.log(c("gray", "          'Perbaiki bug di HealthSystem dan tambahkan regenerasi'"));
  console.log();
  const goal = await ask("Tujuan/fitur yang ingin dibangun:");
  if (!goal.trim()) {
    console.log(c("red", "  Tujuan tidak boleh kosong."));
    return;
  }

  console.log();
  console.log(c("yellow", "  ⏳ ArchitectAI sedang merancang..."));
  try {
    const result = await apiPost("/agent/sessions", { goal });
    console.log();
    console.log(c("green", "  ✅ Sesi dibuat: ") + result.session_id);
    console.log(c("cyan", "\n  RESPONS ARCHITECTAI:"));
    printSeparator();
    const lines = (result.architect_response as string).split("\n");
    for (const line of lines) {
      console.log("  " + line);
    }
    if (result.commands_count > 0) {
      console.log();
      console.log(c("yellow", `  📦 ${result.commands_count} perintah siap untuk Roblox Studio`));
      console.log(c("gray", "  → Pilih [3] untuk melihat detail, atau buka Studio Plugin"));
    }
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function listSessions() {
  console.log();
  console.log(c("cyan", "  📋 DAFTAR SESI"));
  printSeparator();
  try {
    const sessions = await apiGet("/agent/sessions") as Array<{
      id: string; goal: string; status: string;
      message_count: number; created_at: string;
    }>;
    if (sessions.length === 0) {
      console.log(c("gray", "  Belum ada sesi. Buat dengan [1]."));
      return;
    }
    sessions.forEach((s, i) => {
      const statusColor = s.status === "running" ? "green" :
                          s.status === "waiting_studio" ? "yellow" : "gray";
      console.log(
        `  ${c("bright", String(i + 1) + ".")} ${c("cyan", s.id.slice(0, 8))}... ` +
        `[${c(statusColor, s.status)}] ` +
        `${c("reset", s.goal.slice(0, 50))}` +
        (s.goal.length > 50 ? "..." : "") +
        ` ${c("gray", `(${s.message_count} pesan)`)}`
      );
    });
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function viewSession() {
  await listSessions();
  console.log();
  const sessionId = await ask("Masukkan session ID (atau nomor urut):");
  if (!sessionId.trim()) return;

  try {
    let id = sessionId.trim();
    if (/^\d+$/.test(id)) {
      const sessions = await apiGet("/agent/sessions") as Array<{ id: string }>;
      const idx = parseInt(id) - 1;
      if (sessions[idx]) id = sessions[idx].id;
    }

    const session = await apiGet(`/agent/sessions/${id}`) as {
      id: string; goal: string; status: string;
      history: Array<{ role: string; content: string; timestamp: string; commands?: unknown[] }>;
      studio_commands: Array<{ action: string; name?: string; message: string; target?: string }>;
    };
    console.log();
    console.log(c("cyan", "  📌 SESSION: ") + session.id);
    console.log(c("bright", "  Goal: ") + session.goal);
    console.log(c("bright", "  Status: ") + c(
      session.status === "running" ? "green" : session.status === "waiting_studio" ? "yellow" : "gray",
      session.status
    ));
    printSeparator();

    for (const msg of session.history.slice(-6)) {
      printMessage(msg);
    }

    if (session.studio_commands && session.studio_commands.length > 0) {
      console.log();
      console.log(c("yellow", `  📦 PERINTAH PENDING UNTUK STUDIO (${session.studio_commands.length}):`));
      session.studio_commands.forEach((cmd, i) => {
        console.log(
          `  ${i + 1}. ${c("cyan", cmd.action)} → ${c("bright", cmd.target || "?")} / ${cmd.name || ""}`
        );
        console.log(c("gray", `     ${cmd.message}`));
      });
    }
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function sendMessage() {
  await listSessions();
  console.log();
  const sessionId = await ask("Session ID:");
  const message = await ask("Pesan:");
  if (!sessionId.trim() || !message.trim()) return;

  try {
    let id = sessionId.trim();
    if (/^\d+$/.test(id)) {
      const sessions = await apiGet("/agent/sessions") as Array<{ id: string }>;
      const idx = parseInt(id) - 1;
      if (sessions[idx]) id = sessions[idx].id;
    }

    console.log(c("yellow", "\n  ⏳ ArchitectAI sedang merespons..."));
    const result = await apiPost(`/agent/sessions/${id}/message`, { message }) as {
      architect_response: string; commands: unknown[];
    };
    console.log();
    console.log(c("cyan", "  RESPONS ARCHITECTAI:"));
    printSeparator();
    const lines = result.architect_response.split("\n");
    for (const line of lines) console.log("  " + line);
    if (result.commands && result.commands.length > 0) {
      console.log(c("yellow", `\n  📦 ${result.commands.length} perintah baru untuk Studio`));
    }
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function sendStudioReport() {
  await listSessions();
  console.log();
  const sessionId = await ask("Session ID:");
  if (!sessionId.trim()) return;

  let id = sessionId.trim();
  if (/^\d+$/.test(id)) {
    const sessions = await apiGet("/agent/sessions") as Array<{ id: string }>;
    const idx = parseInt(id) - 1;
    if (sessions[idx]) id = sessions[idx].id;
  }

  console.log(c("gray", "\n  Masukkan laporan dari Roblox Studio (tekan Enter 2x untuk selesai):"));
  const lines: string[] = [];
  await new Promise<void>((resolve) => {
    rl.on("line", (line) => {
      if (line === "" && lines[lines.length - 1] === "") {
        resolve();
      } else {
        lines.push(line);
      }
    });
  });

  const reportText = lines.join("\n");
  if (!reportText.trim()) return;

  try {
    console.log(c("yellow", "\n  ⏳ ArchitectAI sedang menganalisa laporan..."));
    const result = await apiPost(`/agent/sessions/${id}/studio-respond`, {
      report_text: reportText,
    }) as { architect_response: string; commands: unknown[] };

    console.log();
    console.log(c("cyan", "  RESPONS ARCHITECTAI:"));
    printSeparator();
    const responseLines = result.architect_response.split("\n");
    for (const line of responseLines) console.log("  " + line);
    if (result.commands && result.commands.length > 0) {
      console.log(c("yellow", `\n  📦 ${result.commands.length} perintah baru`));
    }
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function liveLoop() {
  await listSessions();
  console.log();
  const sessionId = await ask("Session ID untuk live loop:");
  if (!sessionId.trim()) return;

  let id = sessionId.trim();
  if (/^\d+$/.test(id)) {
    const sessions = await apiGet("/agent/sessions") as Array<{ id: string }>;
    const idx = parseInt(id) - 1;
    if (sessions[idx]) id = sessions[idx].id;
  }

  const interval = parseInt(await ask("Interval polling detik (default 5):") || "5") || 5;
  console.log(c("yellow", `\n  🔄 Live mode aktif (interval ${interval}s). Ctrl+C untuk berhenti.`));
  console.log(c("gray", "  Pastikan Roblox Studio Plugin juga berjalan dan terhubung.\n"));

  while (true) {
    try {
      const session = await apiGet(`/agent/sessions/${id}`) as {
        status: string;
        studio_commands: Array<{ action: string; name?: string; message: string }>;
      };
      if (session.studio_commands && session.studio_commands.length > 0) {
        console.log(c("yellow", `  [${new Date().toLocaleTimeString()}] 📦 ${session.studio_commands.length} perintah menunggu Studio...`));
        session.studio_commands.forEach((cmd, i) => {
          console.log(c("gray", `    ${i + 1}. ${cmd.action}: ${cmd.name || cmd.message.slice(0, 60)}`));
        });
      } else {
        process.stdout.write(c("gray", `  [${new Date().toLocaleTimeString()}] Status: ${session.status}\r`));
      }
    } catch (err) {
      console.log(c("red", "  Error: " + String(err)));
    }
    await new Promise((r) => setTimeout(r, interval * 1000));
  }
}

async function simulateStudio() {
  await listSessions();
  console.log();
  const sessionId = await ask("Session ID:");
  if (!sessionId.trim()) return;

  let id = sessionId.trim();
  if (/^\d+$/.test(id)) {
    const sessions = await apiGet("/agent/sessions") as Array<{ id: string }>;
    const idx = parseInt(id) - 1;
    if (sessions[idx]) id = sessions[idx].id;
  }

  try {
    const session = await apiGet(`/agent/sessions/${id}`) as {
      studio_commands: unknown[];
    };
    if (!session.studio_commands || session.studio_commands.length === 0) {
      console.log(c("gray", "  Tidak ada perintah pending."));
      return;
    }

    console.log(c("yellow", `\n  🤖 Mensimulasikan Studio Agent untuk ${session.studio_commands.length} perintah...`));
    const result = await apiPost("/agent/studio-simulate", {
      commands: session.studio_commands,
    }) as { studio_response: string; parsed_report: unknown };

    console.log();
    console.log(c("cyan", "  RESPONS STUDIO AGENT:"));
    printSeparator();
    const lines = result.studio_response.split("\n");
    for (const line of lines) console.log("  " + line);

    if (result.parsed_report) {
      console.log(c("green", "\n  ✅ Laporan berhasil di-parse"));
      const ans = await ask("Kirim laporan ini ke ArchitectAI? (y/n):");
      if (ans.toLowerCase() === "y") {
        const forward = await apiPost(`/agent/sessions/${id}/studio-respond`, {
          report_text: result.studio_response,
        }) as { architect_response: string; commands: unknown[] };
        console.log();
        console.log(c("cyan", "  RESPON ARCHITECTAI SETELAH LAPORAN:"));
        printSeparator();
        forward.architect_response.split("\n").forEach((l) => console.log("  " + l));
      }
    }
  } catch (err) {
    console.log(c("red", "  ❌ Error: " + String(err)));
  }
}

async function showStatus() {
  try {
    const status = await apiGet("/studio/status") as {
      total_sessions: number; running: number;
      waiting_studio: number; completed: number;
    };
    console.log();
    console.log(c("cyan", "  📊 STATUS SISTEM"));
    printSeparator();
    console.log(`  Total sesi    : ${c("bright", String(status.total_sessions))}`);
    console.log(`  Running       : ${c("green", String(status.running))}`);
    console.log(`  Waiting Studio: ${c("yellow", String(status.waiting_studio))}`);
    console.log(`  Completed     : ${c("gray", String(status.completed))}`);
  } catch (err) {
    console.log(c("red", "  ❌ API tidak dapat dijangkau: " + String(err)));
    console.log(c("gray", `  Pastikan API server berjalan di ${API_BASE}`));
  }
}

async function main() {
  printHeader();
  console.log(c("gray", `  API Server: ${API_BASE}\n`));

  while (true) {
    printMenu();
    const choice = await ask("Pilih menu [0-8]:");

    printHeader();

    switch (choice.trim()) {
      case "1": await createSession(); break;
      case "2": await listSessions(); break;
      case "3": await viewSession(); break;
      case "4": await sendMessage(); break;
      case "5": await sendStudioReport(); break;
      case "6": await liveLoop(); break;
      case "7": await simulateStudio(); break;
      case "8": await showStatus(); break;
      case "0":
        console.log(c("cyan", "\n  Sampai jumpa! 👋\n"));
        rl.close();
        process.exit(0);
      default:
        console.log(c("red", "  Pilihan tidak valid."));
    }

    console.log();
    await ask("Tekan Enter untuk kembali ke menu...");
    printHeader();
  }
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
