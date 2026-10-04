import Anthropic from '@anthropic-ai/sdk';
import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';
import { AiCompletionRequest, AiProvider, AiProviderError } from './ai.provider';

export class AnthropicAiProvider implements AiProvider {
  private client: Anthropic;
  private model: string;

  constructor() {
    const config = loadConfig();
    this.client = new Anthropic({ apiKey: config.ANTHROPIC_API_KEY });
    this.model = config.ANTHROPIC_MODEL;
  }

  async complete(request: AiCompletionRequest): Promise<string> {
    try {
      const response = await this.client.messages.create({
        model: this.model,
        max_tokens: request.maxTokens ?? 512,
        system: request.systemPrompt,
        messages: request.messages.map((m) => ({ role: m.role, content: m.content })),
      });

      const textBlock = response.content.find((block) => block.type === 'text');
      if (!textBlock || textBlock.type !== 'text') {
        throw new AiProviderError('AI provider returned no text content');
      }
      return textBlock.text;
    } catch (err) {
      if (err instanceof AiProviderError) throw err;
      logger.error({ err }, 'Anthropic API request failed');
      throw new AiProviderError('AI provider request failed');
    }
  }
}
