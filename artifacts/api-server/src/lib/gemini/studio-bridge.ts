export interface StudioCommand {
  action:
    | "create_script"
    | "create_part"
    | "create_model"
    | "modify_script"
    | "test_game"
    | "report_status";
  target: string;
  name?: string;
  content?: string;
  properties?: Record<string, unknown>;
  message: string;
}

export interface StudioReport {
  status: "success" | "error" | "needs_clarification" | "pending";
  action_taken: string;
  files_created: string[];
  files_modified: string[];
  errors: string[];
  questions: string[];
  next_suggested_action: string;
  raw_output?: string;
}

export interface AgentSession {
  id: string;
  goal: string;
  history: AgentMessage[];
  status: "running" | "waiting_studio" | "completed" | "error";
  created_at: string;
  updated_at: string;
  studio_commands: StudioCommand[];
  studio_reports: StudioReport[];
}

export interface AgentMessage {
  role: "architect" | "studio" | "user" | "system";
  content: string;
  timestamp: string;
  commands?: StudioCommand[];
  report?: StudioReport;
}

export function parseStudioCommands(text: string): StudioCommand[] {
  const commands: StudioCommand[] = [];
  const regex = /```studio_command\s*([\s\S]*?)```/g;
  let match;
  while ((match = regex.exec(text)) !== null) {
    try {
      const cmd = JSON.parse(match[1].trim()) as StudioCommand;
      commands.push(cmd);
    } catch {
      // skip malformed
    }
  }
  return commands;
}

export function parseStudioReport(text: string): StudioReport | null {
  const regex = /```studio_report\s*([\s\S]*?)```/s;
  const match = regex.exec(text);
  if (!match) return null;
  try {
    return JSON.parse(match[1].trim()) as StudioReport;
  } catch {
    return null;
  }
}

const sessions = new Map<string, AgentSession>();

export function createSession(id: string, goal: string): AgentSession {
  const session: AgentSession = {
    id,
    goal,
    history: [],
    status: "running",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    studio_commands: [],
    studio_reports: [],
  };
  sessions.set(id, session);
  return session;
}

export function getSession(id: string): AgentSession | undefined {
  return sessions.get(id);
}

export function getAllSessions(): AgentSession[] {
  return Array.from(sessions.values()).sort(
    (a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );
}

export function updateSession(
  id: string,
  updates: Partial<AgentSession>
): AgentSession | undefined {
  const session = sessions.get(id);
  if (!session) return undefined;
  Object.assign(session, updates, { updated_at: new Date().toISOString() });
  return session;
}

export function deleteSession(id: string): boolean {
  return sessions.delete(id);
}
