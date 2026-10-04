import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';
import { AiCompletionRequest, AiProvider, AiProviderError } from './ai.provider';

interface GroqChatResponse {
  choices?: { message?: { content?: string } }[];
  error?: { message?: string };
}

/**
 * Groq (groq.com) — fast inference for open models via an OpenAI-compatible chat completions
 * API. Distinct from xAI's "Grok" model despite the near-identical name; this targets Groq's
 * actual API (api.groq.com), keyed by GROQ_API_KEY (format `gsk_...`).
 */
export class GroqAiProvider implements AiProvider {
  async complete(request: AiCompletionRequest): Promise<string> {
    const config = loadConfig();

    let response: Response;
    try {
      response = await fetch(`${config.GROQ_BASE_URL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: config.GROQ_MODEL,
          max_tokens: request.maxTokens ?? 512,
          messages: [
            { role: 'system', content: request.systemPrompt },
            ...request.messages.map((m) => ({ role: m.role, content: m.content })),
          ],
        }),
      });
    } catch (err) {
      logger.error({ err }, 'Groq API request failed');
      throw new AiProviderError('AI provider request failed');
    }

    const data = (await response.json()) as GroqChatResponse;

    if (!response.ok) {
      logger.error({ status: response.status, error: data.error }, 'Groq API returned an error');
      throw new AiProviderError(data.error?.message ?? 'AI provider request failed');
    }

    const text = data.choices?.[0]?.message?.content;
    if (!text) {
      throw new AiProviderError('AI provider returned no text content');
    }
    return text;
  }
}
