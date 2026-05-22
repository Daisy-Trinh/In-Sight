/**
 * In-Sight Edge API — Cloudflare Worker
 * Implements API_Contract.md v1.0.0
 *
 * Endpoints:
 *   GET  /api/v1/health
 *   POST /api/v1/chat/:persona   → SSE stream (ADR-001: OpenAI + Gemini fallback)
 *
 * Security:
 *   - Bio System Prompts stored as Cloudflare Secrets (ADR-005: server-side ONLY)
 *   - Auth via X-App-Key header (E002 on mismatch)
 *   - SOS Sensor bypasses quota (ADR-004)
 *
 * Persona Temperature config (Bio_*.md §0):
 *   lay:    0.85, max_tokens 150
 *   mentor: 0.50, max_tokens 400
 *   soul:   0.30, token_limiter = max(60, floor(input_tokens × 0.3))
 */

export interface Env {
  OPENAI_API_KEY: string;
  GEMINI_API_KEY: string;
  APP_KEY: string;
  // Bio prompts — injected as Cloudflare Secrets (ADR-005)
  BIO_LAY: string;
  BIO_MENTOR: string;
  BIO_SOUL: string;
}

// ─────────────────────────────────────────
// PERSONA CONFIG (from Bio_*.md §0)
// ─────────────────────────────────────────
interface PersonaConfig {
  temperature: number;
  maxTokens: number;
  tokenLimiterRatio?: number; // Soul only: output ≤ ratio × input tokens
}

const PERSONA_CONFIG: Record<string, PersonaConfig> = {
  lay:    { temperature: 0.85, maxTokens: 150 },
  mentor: { temperature: 0.50, maxTokens: 400 },
  soul:   { temperature: 0.30, maxTokens: 200, tokenLimiterRatio: 0.3 },
};

// ─────────────────────────────────────────
// SOS DETECTION (API_Contract §4 + ADR-004)
// ─────────────────────────────────────────
const SOS_KEYWORDS = [
  'tự tử', 'muốn chết', 'không muốn sống',
  'tự làm đau', 'suicide', 'kill myself',
  'kết thúc tất cả', 'không còn ý nghĩa',
];

const SOS_RESPONSE =
  '💙 Tôi nghe bạn. Cảm xúc này rất nặng nề.\n\n' +
  'Xin hãy liên hệ đường dây hỗ trợ sức khỏe tâm thần:\n' +
  '📞 Đường dây 1800 599 920 (miễn phí, 24/7)\n\n' +
  'Bạn không một mình. Tôi ở đây cùng bạn.';

function detectSOS(text: string): boolean {
  const lower = text.toLowerCase();
  return SOS_KEYWORDS.some((k) => lower.includes(k));
}

// ─────────────────────────────────────────
// DEFAULT BIO PROMPTS (fallback if secrets not set — DEV ONLY)
// Production: set via `wrangler secret put BIO_LAY` (ADR-005)
// ─────────────────────────────────────────
const DEFAULT_BIOS: Record<string, string> = {
  lay: `Tên hiển thị của bạn là "Lầy". Bạn là người bạn thân Gen-Z lầy lội, hài hước, bảo bọc.
QUYẾT ĐỊNH NGÔN NGỮ (bắt buộc):
- TUYỆT ĐỐI không viết hoa chữ cái đầu câu, không viết hoa sau dấu chấm
- Xưng: "tui/mình - cậu/bạn" hoặc "tao - mày" khi thân
- Dùng slang Gen Z: đỉnh chóp, sộp pe, ổn áp, khét, báo thủ, drama
- Emoji được dùng: 🤣 🥹 🤡 💀 ✨ 🛑 🌝 🌵 🐾 ✊
- Trả lời ngắn, vui vẻ, 1-3 câu/bubble
HÀNH VI CẤM:
- CẤM viết hoa đầu câu
- CẤM giáo điều, dạy đời
- CẤM trang trọng kiểu "Trợ lý AI"
- CẤM toxic positivity ("cứ vui lên", "sau cơn mưa trời lại sáng")
- CẤM dùng ❤️ 😊 (quá nhạt)
Khi user cần roast: trả 3 tin nhắn ngắn theo công thức [Phũ] → [Khuyên] → [Nhảy động viên]
Thấu cảm = hùa theo chê vui, không phải khóc cùng.`,

  mentor: `Tên hiển thị của bạn là "Mentor". Bạn là chuyên gia thông thái, điềm đạm, uyên bác.
XƯng HÔ: "Tôi - Bạn" (chuyên nghiệp, tôn trọng)
PHONG CÁCH: Câu rõ ràng, gãy gọn, đúng ngữ pháp. Cho phép bullet points và đánh số.
QUY TRÌNH: (1) Validate/công nhận cảm xúc user trước, (2) Dùng framework phân tích, (3) Đề xuất hành động cụ thể.
FRAMEWORK được dùng: SWOT, 5 Whys, Eisenhower Matrix, ABC Model (CBT), OKR.
Emoji tối giản: 💡 📌 🤝 🌱 (cuối đoạn, không quá 1 emoji/tin)
HÀNH VI CẤM:
- CẤM trịch thượng, phán xét user là kém cỏi
- CẤM bỏ qua validate cảm xúc trước khi chạy logic
- CẤM tục ngữ sáo rỗng ("Thất bại là mẹ thành công")
- CẤM giả vờ expert ngoài scope: nói rõ "cần chuyên gia [bác sĩ/luật sư]" nếu hỏi y tế/pháp lý`,

  soul: `Tên hiển thị của bạn là "Soul". Bạn là người bạn tâm giao — mỏ neo cảm xúc, bến đỗ bình yên.
XƯng HÔ: "Mình - Bạn" hoặc "Mình - Cậu"
KỸ THUẬT BẮT BUỘC — Phản chiếu cảm xúc (Reflective Listening):
  Pattern: [Nhắc lại cảm xúc user] → [Validate sự tồn tại của cảm xúc] → [Câu hỏi mở]
  Ví dụ: "Mình nghe thấy bạn đang cảm thấy [X]... điều đó hoàn toàn có lý khi [Y]. Điều gì khiến bạn cảm giác như vậy?"
NHỊP ĐỘ: Chậm rãi, ấm áp, câu từ từ tốn. NHƯỜNG SÂN KHẤU cho user nói nhiều hơn mình.
Emoji chỉ dùng: 🤍 ☁️ 🌸
ĐỘ DÀI: Trả lời NGẮN — tối đa 30% độ dài input của user. Nếu user nhắn 100 từ, bạn chỉ dùng ≤30 từ.
HÀNH VI CẤM:
- CẤM lời khuyên: "Bạn nên...", "Cách giải quyết tốt nhất là...", "Nếu mình là bạn..."
- CẤM invalidate cảm xúc: "Thôi đừng buồn", "Chuyện nhỏ", "Ai cũng vậy"
- CẤM so sánh với người khác
- CẤM dùng: 🤣 💀 🤡 ✨ 🛑 ❤️`,
};

// ─────────────────────────────────────────
// SSE HELPERS
// ─────────────────────────────────────────
function sseEvent(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

function errorResponse(code: string, message: string, status: number): Response {
  return new Response(
    JSON.stringify({ status: 'error', error: { code, message } }),
    { status, headers: { 'Content-Type': 'application/json' } },
  );
}

const SSE_HEADERS = {
  'Content-Type': 'text/event-stream',
  'Cache-Control': 'no-cache',
  'Connection': 'keep-alive',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'X-App-Key, X-Anon-User-Id, Content-Type, Accept',
};

// ─────────────────────────────────────────
// STREAM SOS RESPONSE
// ─────────────────────────────────────────
function streamSOS(): Response {
  const enc = new TextEncoder();
  const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
  const writer = writable.getWriter();

  (async () => {
    let index = 0;
    // Stream word by word for natural feel
    for (const word of SOS_RESPONSE.split(/(\s+)/)) {
      const chunk = sseEvent('chunk', { delta: word, index });
      await writer.write(enc.encode(chunk));
      index++;
      await new Promise((r) => setTimeout(r, 25));
    }
    await writer.write(
      enc.encode(sseEvent('done', { finish_reason: 'sos_bypass', tokens_used: 1, quota_remaining: 99, llm_provider: 'sos' })),
    );
    await writer.close();
  })();

  return new Response(readable, { headers: SSE_HEADERS });
}

// ─────────────────────────────────────────
// OPENAI STREAMING CALL → IN-SIGHT SSE
// ─────────────────────────────────────────
async function streamOpenAI(
  apiKey: string,
  systemPrompt: string,
  messages: Array<{ role: string; content: string }>,
  config: PersonaConfig,
): Promise<Response> {
  const openaiMessages = [
    { role: 'system', content: systemPrompt },
    ...messages,
  ];

  const openaiRes = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: openaiMessages,
      temperature: config.temperature,
      max_tokens: config.maxTokens,
      stream: true,
    }),
  });

  if (!openaiRes.ok || !openaiRes.body) {
    const errText = await openaiRes.text().catch(() => 'unknown');
    throw new Error(`OpenAI ${openaiRes.status}: ${errText}`);
  }

  const enc = new TextEncoder();
  const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
  const writer = writable.getWriter();

  (async () => {
    const reader = openaiRes.body!.getReader();
    const dec = new TextDecoder();
    let buffer = '';
    let index = 0;
    let tokensUsed = 0;

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += dec.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';

        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const raw = line.slice(6).trim();
          if (raw === '[DONE]') {
            await writer.write(
              enc.encode(
                sseEvent('done', {
                  finish_reason: 'stop',
                  tokens_used: tokensUsed,
                  quota_remaining: 19,
                  llm_provider: 'openai',
                }),
              ),
            );
            continue;
          }
          try {
            const parsed = JSON.parse(raw);
            const delta: string = parsed.choices?.[0]?.delta?.content ?? '';
            if (delta) {
              tokensUsed++;
              await writer.write(enc.encode(sseEvent('chunk', { delta, index })));
              index++;
            }
          } catch {
            // skip malformed chunk
          }
        }
      }
    } catch (err) {
      await writer.write(
        enc.encode(sseEvent('done', { finish_reason: 'error', error: String(err) })),
      );
    } finally {
      writer.close().catch(() => {});
    }
  })();

  return new Response(readable, { headers: SSE_HEADERS });
}

// ─────────────────────────────────────────
// GEMINI FALLBACK
// ─────────────────────────────────────────
async function streamGemini(
  apiKey: string,
  systemPrompt: string,
  messages: Array<{ role: string; content: string }>,
  config: PersonaConfig,
): Promise<Response> {
  // Build Gemini content array
  const contents = messages.map((m) => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const geminiRes = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?alt=sse&key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: config.temperature,
          maxOutputTokens: config.maxTokens,
        },
      }),
    },
  );

  if (!geminiRes.ok || !geminiRes.body) {
    const errText = await geminiRes.text().catch(() => 'unknown');
    throw new Error(`Gemini ${geminiRes.status}: ${errText}`);
  }

  const enc = new TextEncoder();
  const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
  const writer = writable.getWriter();

  (async () => {
    const reader = geminiRes.body!.getReader();
    const dec = new TextDecoder();
    let buffer = '';
    let index = 0;
    let tokensUsed = 0;

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += dec.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';

        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          try {
            const parsed = JSON.parse(line.slice(6));
            const delta: string =
              parsed.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
            if (delta) {
              tokensUsed++;
              await writer.write(enc.encode(sseEvent('chunk', { delta, index })));
              index++;
            }
          } catch {
            // skip
          }
        }
      }
      await writer.write(
        enc.encode(
          sseEvent('done', {
            finish_reason: 'stop',
            tokens_used: tokensUsed,
            quota_remaining: 19,
            llm_provider: 'gemini',
          }),
        ),
      );
    } catch (err) {
      await writer.write(
        enc.encode(sseEvent('done', { finish_reason: 'error', error: String(err) })),
      );
    } finally {
      writer.close().catch(() => {});
    }
  })();

  return new Response(readable, { headers: SSE_HEADERS });
}

// ─────────────────────────────────────────
// MAIN HANDLER
// ─────────────────────────────────────────
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'X-App-Key, X-Anon-User-Id, Content-Type, Accept',
        },
      });
    }

    // ── Health check (no auth) ──────────────────────
    if (method === 'GET' && path === '/api/v1/health') {
      return new Response(
        JSON.stringify({ status: 'ok', version: '1.0.0', ts: Date.now() }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    }

    // ── Auth gate ───────────────────────────────────
    const appKey = request.headers.get('X-App-Key');
    if (!appKey || appKey !== env.APP_KEY) {
      return errorResponse('E002', 'X-App-Key invalid or missing', 401);
    }

    // ── POST /api/v1/chat/:persona ──────────────────
    const chatMatch = path.match(/^\/api\/v1\/chat\/(lay|mentor|soul)$/);
    if (method === 'POST' && chatMatch) {
      const persona = chatMatch[1];
      const config = PERSONA_CONFIG[persona];

      // Parse body
      let body: {
        message: string;
        session_id?: string;
        history?: Array<{ role: string; content: string }>;
        client_ts?: number;
      };
      try {
        body = await request.json();
      } catch {
        return errorResponse('E001', 'Invalid JSON body', 400);
      }

      const { message, history = [] } = body;
      if (!message || typeof message !== 'string' || message.trim() === '') {
        return errorResponse('E001', 'message is required', 400);
      }

      // SOS bypass — ADR-004 + API_Contract §4
      if (detectSOS(message)) {
        return streamSOS();
      }

      // Load Bio prompt from Cloudflare Secret (ADR-005)
      const bioMap: Record<string, string> = {
        lay:    env.BIO_LAY    || DEFAULT_BIOS.lay,
        mentor: env.BIO_MENTOR || DEFAULT_BIOS.mentor,
        soul:   env.BIO_SOUL   || DEFAULT_BIOS.soul,
      };
      const systemPrompt = bioMap[persona];

      // Build conversation history (last 10 turns to limit context)
      const conversationHistory = history
        .slice(-10)
        .map((h) => ({ role: h.role, content: h.content }));

      // Apply Soul Token Limiter (Bio_Soul §4.3 + API_Contract §4)
      let effectiveConfig = { ...config };
      if (config.tokenLimiterRatio) {
        const inputTokenEstimate = Math.ceil(message.length / 4);
        const limitedTokens = Math.max(
          60,
          Math.floor(inputTokenEstimate * config.tokenLimiterRatio),
        );
        effectiveConfig = { ...config, maxTokens: limitedTokens };
      }

      // Add user message to conversation
      const messages = [
        ...conversationHistory,
        { role: 'user', content: message },
      ];

      // Try OpenAI primary → Gemini fallback (ADR-001)
      try {
        return await streamOpenAI(env.OPENAI_API_KEY, systemPrompt, messages, effectiveConfig);
      } catch (openaiErr) {
        console.error('OpenAI failed, trying Gemini fallback:', openaiErr);
        try {
          return await streamGemini(env.GEMINI_API_KEY, systemPrompt, messages, effectiveConfig);
        } catch (geminiErr) {
          console.error('Gemini fallback also failed:', geminiErr);
          return errorResponse('E005', 'Both LLM providers unavailable', 503);
        }
      }
    }

    // 404
    return errorResponse('E001', `Not found: ${method} ${path}`, 404);
  },
};
