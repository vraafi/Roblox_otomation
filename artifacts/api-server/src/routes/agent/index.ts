import { Router } from "express";
import { randomUUID } from "crypto";
import { generateWithRotation } from "../../lib/gemini/client.js";
import {
  REPO_AGENT_SYSTEM,
  STUDIO_AGENT_SYSTEM,
} from "../../lib/gemini/agent-prompts.js";
import {
  createSession,
  getSession,
  getAllSessions,
  updateSession,
  deleteSession,
  parseStudioCommands,
  parseStudioReport,
  type AgentMessage,
} from "../../lib/gemini/studio-bridge.js";

const router = Router();

router.post("/agent/sessions", async (req, res) => {
  try {
    const { goal } = req.body as { goal?: string };
    if (!goal) {
      res.status(400).json({ error: "Field 'goal' wajib diisi" });
      return;
    }

    const id = randomUUID();
    const session = createSession(id, goal);

    const initPrompt = `Tujuan game yang ingin dibangun: ${goal}

Mulai dengan:
1. Analisa tujuan ini
2. Rancang arsitektur game (sistem utama yang diperlukan)
3. Buat perintah pertama untuk Studio Agent: mulai dengan script paling fundamental

Ingat, ini adalah Hardcore Extraction Fantasy Game dengan sistem yang sudah ada di repo:
- PlayerManager, StatSystem, HealthSystem, InventorySystem, ItemDatabase
- Banyak item batch scripts (ITEMS_BATCH_*), monster batch, weapon batch
- Biome Kalimantan, lobby spaceship, weather/disaster system

Identifikasi apa yang masih kurang dan mulai membangunnya.`;

    const architectResponse = await generateWithRotation(
      initPrompt,
      REPO_AGENT_SYSTEM
    );

    const commands = parseStudioCommands(architectResponse);

    const msg: AgentMessage = {
      role: "architect",
      content: architectResponse,
      timestamp: new Date().toISOString(),
      commands,
    };

    updateSession(id, {
      history: [msg],
      status: commands.length > 0 ? "waiting_studio" : "running",
      studio_commands: commands,
    });

    res.status(201).json({
      session_id: id,
      architect_response: architectResponse,
      commands_count: commands.length,
      commands,
      status: session.status,
    });
  } catch (err) {
    req.log.error(err);
    res.status(500).json({ error: "Gagal memulai sesi agent" });
  }
});

router.get("/agent/sessions", (_req, res) => {
  const sessions = getAllSessions().map((s) => ({
    id: s.id,
    goal: s.goal,
    status: s.status,
    message_count: s.history.length,
    created_at: s.created_at,
    updated_at: s.updated_at,
  }));
  res.json(sessions);
});

router.get("/agent/sessions/:id", (req, res) => {
  const session = getSession(req.params.id);
  if (!session) {
    res.status(404).json({ error: "Sesi tidak ditemukan" });
    return;
  }
  res.json(session);
});

router.delete("/agent/sessions/:id", (req, res) => {
  const deleted = deleteSession(req.params.id);
  if (!deleted) {
    res.status(404).json({ error: "Sesi tidak ditemukan" });
    return;
  }
  res.status(204).send();
});

router.post("/agent/sessions/:id/message", async (req, res) => {
  try {
    const session = getSession(req.params.id);
    if (!session) {
      res.status(404).json({ error: "Sesi tidak ditemukan" });
      return;
    }

    const { message, role } = req.body as {
      message: string;
      role?: "user" | "studio";
    };
    if (!message) {
      res.status(400).json({ error: "Field 'message' wajib diisi" });
      return;
    }

    const msgRole = role === "studio" ? "studio" : "user";
    const incomingMsg: AgentMessage = {
      role: msgRole,
      content: message,
      timestamp: new Date().toISOString(),
    };

    const updatedHistory = [...session.history, incomingMsg];

    const historyContext = updatedHistory
      .slice(-10)
      .map((m) => {
        const label =
          m.role === "architect"
            ? "ArchitectAI"
            : m.role === "studio"
              ? "StudioAI"
              : "User";
        return `[${label}]: ${m.content}`;
      })
      .join("\n\n---\n\n");

    const isStudioReport = msgRole === "studio";
    const systemPrompt = isStudioReport
      ? REPO_AGENT_SYSTEM
      : REPO_AGENT_SYSTEM;

    const prompt = isStudioReport
      ? `Berikut laporan terbaru dari Studio Agent:\n\n${message}\n\n---\nRiwayat diskusi:\n${historyContext}\n\nAnalisa laporan ini dan tentukan langkah selanjutnya. Jika ada error, berikan solusi. Jika sukses, lanjutkan membangun fitur berikutnya.`
      : `Pesan baru: ${message}\n\n---\nRiwayat diskusi:\n${historyContext}\n\nRespond sesuai konteks.`;

    const architectResponse = await generateWithRotation(prompt, systemPrompt);
    const commands = parseStudioCommands(architectResponse);

    const architectMsg: AgentMessage = {
      role: "architect",
      content: architectResponse,
      timestamp: new Date().toISOString(),
      commands,
    };

    updateSession(req.params.id, {
      history: [...updatedHistory, architectMsg],
      status: commands.length > 0 ? "waiting_studio" : "running",
      studio_commands: [
        ...(session.studio_commands || []),
        ...commands,
      ],
    });

    res.json({
      architect_response: architectResponse,
      commands_count: commands.length,
      commands,
      status: commands.length > 0 ? "waiting_studio" : "running",
    });
  } catch (err) {
    req.log.error(err);
    res.status(500).json({ error: "Gagal memproses pesan" });
  }
});

router.post("/agent/sessions/:id/studio-respond", async (req, res) => {
  try {
    const session = getSession(req.params.id);
    if (!session) {
      res.status(404).json({ error: "Sesi tidak ditemukan" });
      return;
    }

    const { report_text } = req.body as { report_text: string };
    if (!report_text) {
      res.status(400).json({ error: "Field 'report_text' wajib diisi" });
      return;
    }

    const parsedReport = parseStudioReport(report_text);

    const studioMsg: AgentMessage = {
      role: "studio",
      content: report_text,
      timestamp: new Date().toISOString(),
      report: parsedReport ?? undefined,
    };

    const history = [...session.history, studioMsg];

    const historyContext = history
      .slice(-8)
      .map((m) => {
        const label =
          m.role === "architect"
            ? "ArchitectAI"
            : m.role === "studio"
              ? "StudioAI"
              : "User";
        return `[${label}]: ${m.content}`;
      })
      .join("\n\n---\n\n");

    const prompt = `Laporan dari Studio Agent:\n${report_text}\n\n---\nRiwayat:\n${historyContext}\n\nAnalisa laporan, atasi masalah jika ada, dan lanjutkan pembangunan game.`;

    const architectResponse = await generateWithRotation(
      prompt,
      REPO_AGENT_SYSTEM
    );
    const commands = parseStudioCommands(architectResponse);

    const architectMsg: AgentMessage = {
      role: "architect",
      content: architectResponse,
      timestamp: new Date().toISOString(),
      commands,
    };

    updateSession(req.params.id, {
      history: [...history, architectMsg],
      status: commands.length > 0 ? "waiting_studio" : "running",
      studio_commands: [...(session.studio_commands || []), ...commands],
      studio_reports: [
        ...(session.studio_reports || []),
        parsedReport ?? {
          status: "pending",
          action_taken: report_text,
          files_created: [],
          files_modified: [],
          errors: [],
          questions: [],
          next_suggested_action: "",
          raw_output: report_text,
        },
      ],
    });

    res.json({
      architect_response: architectResponse,
      commands,
      parsed_report: parsedReport,
    });
  } catch (err) {
    req.log.error(err);
    res.status(500).json({ error: "Gagal memproses laporan studio" });
  }
});

router.post("/agent/studio-simulate", async (req, res) => {
  try {
    const { commands, context } = req.body as {
      commands: unknown[];
      context?: string;
    };

    if (!commands || !Array.isArray(commands)) {
      res.status(400).json({ error: "Field 'commands' wajib diisi (array)" });
      return;
    }

    const prompt = `Kamu adalah Studio Agent di Roblox Studio.

Kamu menerima perintah-perintah berikut dari ArchitectAI:

${JSON.stringify(commands, null, 2)}

${context ? `Konteks tambahan: ${context}` : ""}

Simulasikan eksekusi perintah ini:
1. Periksa setiap perintah untuk validitas Lua syntax
2. Identifikasi apakah perintah bisa dijalankan di Roblox Studio
3. Buat laporan eksekusi

Buat script Lua yang lengkap dan valid untuk setiap create_script command.
Kemudian buat laporan dalam format studio_report.`;

    const studioResponse = await generateWithRotation(
      prompt,
      STUDIO_AGENT_SYSTEM
    );
    const report = parseStudioReport(studioResponse);

    res.json({
      studio_response: studioResponse,
      parsed_report: report,
    });
  } catch (err) {
    req.log.error(err);
    res.status(500).json({ error: "Gagal mensimulasikan studio" });
  }
});

export default router;
