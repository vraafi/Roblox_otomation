import { GoogleGenerativeAI } from "@google/generative-ai";

const ALL_KEYS = [
  process.env.GOOGLE_AI_KEY_1,
  process.env.GOOGLE_AI_KEY_2,
  process.env.GOOGLE_AI_KEY_3,
  process.env.GOOGLE_AI_KEY_4,
  process.env.GOOGLE_AI_KEY_5,
  process.env.GOOGLE_AI_KEY_6,
  process.env.GOOGLE_AI_KEY_7,
  process.env.GOOGLE_AI_KEY_8,
  process.env.GOOGLE_AI_KEY_9,
  process.env.GOOGLE_AI_KEY_10,
].filter(Boolean) as string[];

if (ALL_KEYS.length === 0) {
  throw new Error("Tidak ada GOOGLE_AI_KEY_* di environment.");
}

export const MODEL_NAME = "gemma-4-31b-it" as const;

// Keys yang permanent denied (403) — tidak dicoba lagi sampai restart
const deniedKeys = new Set<string>();
// Keys yang sedang rate-limited sementara
const rateLimitedUntil = new Map<string, number>();

function getAvailableKeys(): string[] {
  const now = Date.now();
  return ALL_KEYS.filter((k) => {
    if (deniedKeys.has(k)) return false;
    const until = rateLimitedUntil.get(k);
    if (until && now < until) return false;
    return true;
  });
}

// Probe semua key saat startup untuk menemukan yang valid
let probedKeys: string[] | null = null;

async function probeKey(key: string): Promise<boolean> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: "hi" }] }],
          generationConfig: { maxOutputTokens: 1 },
        }),
        signal: controller.signal,
      }
    );
    clearTimeout(timer);
    if (res.status === 403) {
      deniedKeys.add(key);
      const idx = ALL_KEYS.indexOf(key) + 1;
      console.warn(`[Gemini] KEY_${idx} ditolak (403), dilewati.`);
      return false;
    }
    if (res.status === 429) {
      rateLimitedUntil.set(key, Date.now() + 60_000);
      const idx = ALL_KEYS.indexOf(key) + 1;
      console.warn(`[Gemini] KEY_${idx} rate limited, dijadwalkan ulang.`);
      return false;
    }
    return true;
  } catch {
    clearTimeout(timer);
    return false;
  }
}

async function getValidKeys(): Promise<string[]> {
  if (probedKeys !== null) {
    const stillValid = probedKeys.filter((k) => !deniedKeys.has(k));
    if (stillValid.length > 0) return stillValid;
    // Reset probe jika semua expired
    probedKeys = null;
  }

  // Probe semua key secara paralel
  const results = await Promise.all(ALL_KEYS.map((k) => probeKey(k)));
  probedKeys = ALL_KEYS.filter((_, i) => results[i]);

  if (probedKeys.length === 0) {
    // Semua denied — reset rate limits dan coba lagi dengan yang belum denied
    rateLimitedUntil.clear();
    probedKeys = ALL_KEYS.filter((k) => !deniedKeys.has(k));
  }

  return probedKeys;
}

let currentIndex = 0;

export async function generateWithRotation(
  prompt: string,
  systemInstruction?: string
): Promise<string> {
  const validKeys = await getValidKeys();

  if (validKeys.length === 0) {
    throw new Error(
      "Semua API key ditolak (403 PERMISSION_DENIED). Tambahkan key baru yang memiliki akses ke model Gemma 4."
    );
  }

  // Coba tiap key valid sekali
  for (let attempt = 0; attempt < validKeys.length; attempt++) {
    const key = validKeys[currentIndex % validKeys.length];
    currentIndex = (currentIndex + 1) % validKeys.length;
    const keyIdx = ALL_KEYS.indexOf(key) + 1;

    try {
      const client = new GoogleGenerativeAI(key);
      const model = client.getGenerativeModel({
        model: MODEL_NAME,
        ...(systemInstruction ? { systemInstruction } : {}),
      });
      const result = await model.generateContent(prompt);
      return result.response.text();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      const isDenied =
        msg.includes("403") ||
        msg.includes("PERMISSION_DENIED") ||
        msg.includes("denied access");
      const isRateLimit =
        msg.includes("429") ||
        msg.includes("quota") ||
        msg.includes("RESOURCE_EXHAUSTED");

      if (isDenied) {
        deniedKeys.add(key);
        probedKeys = probedKeys?.filter((k) => k !== key) ?? null;
        console.warn(`[Gemini] KEY_${keyIdx} ditolak (403), dilewati.`);
        continue;
      }
      if (isRateLimit) {
        rateLimitedUntil.set(key, Date.now() + 60_000);
        probedKeys = probedKeys?.filter((k) => k !== key) ?? null;
        console.warn(`[Gemini] KEY_${keyIdx} rate limited.`);
        continue;
      }
      throw err;
    }
  }

  throw new Error(
    `Semua ${validKeys.length} API key valid gagal. Denied: ${deniedKeys.size}.`
  );
}
