import { Router } from "express";
import { getSession, getAllSessions, updateSession } from "../../lib/gemini/studio-bridge.js";

const router = Router();

router.get("/studio/pending-commands", (req, res) => {
  const { session_id } = req.query as { session_id?: string };

  if (session_id) {
    const session = getSession(session_id);
    if (!session) {
      res.status(404).json({ error: "Sesi tidak ditemukan" });
      return;
    }
    res.json({
      session_id,
      status: session.status,
      commands: session.studio_commands,
      goal: session.goal,
    });
    return;
  }

  const waiting = getAllSessions().filter((s) => s.status === "waiting_studio");
  res.json(
    waiting.map((s) => ({
      session_id: s.id,
      goal: s.goal,
      commands: s.studio_commands,
      command_count: s.studio_commands.length,
    }))
  );
});

router.post("/studio/report", async (req, res) => {
  try {
    const { session_id, status, action_taken, files_created, files_modified, errors, questions, next_suggested_action } =
      req.body as {
        session_id: string;
        status: "success" | "error" | "needs_clarification";
        action_taken: string;
        files_created?: string[];
        files_modified?: string[];
        errors?: string[];
        questions?: string[];
        next_suggested_action?: string;
      };

    if (!session_id || !status || !action_taken) {
      res.status(400).json({ error: "session_id, status, action_taken wajib diisi" });
      return;
    }

    const session = getSession(session_id);
    if (!session) {
      res.status(404).json({ error: "Sesi tidak ditemukan" });
      return;
    }

    const report = {
      status,
      action_taken,
      files_created: files_created ?? [],
      files_modified: files_modified ?? [],
      errors: errors ?? [],
      questions: questions ?? [],
      next_suggested_action: next_suggested_action ?? "",
    };

    updateSession(session_id, {
      status: "running",
      studio_reports: [...(session.studio_reports ?? []), report],
      studio_commands: [],
    });

    res.json({ received: true, session_id });
  } catch (err) {
    req.log.error(err);
    res.status(500).json({ error: "Gagal menyimpan laporan" });
  }
});

router.get("/studio/status", (_req, res) => {
  const sessions = getAllSessions();
  res.json({
    total_sessions: sessions.length,
    running: sessions.filter((s) => s.status === "running").length,
    waiting_studio: sessions.filter((s) => s.status === "waiting_studio").length,
    completed: sessions.filter((s) => s.status === "completed").length,
  });
});

export default router;
