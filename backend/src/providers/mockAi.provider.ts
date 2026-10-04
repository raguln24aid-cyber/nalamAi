import { AiCompletionRequest, AiProvider } from './ai.provider';

/** Deterministic fake for tests/local dev without an Anthropic API key (AI_PROVIDER=mock). */
export class MockAiProvider implements AiProvider {
  async complete(request: AiCompletionRequest): Promise<string> {
    const lastUser = [...request.messages].reverse().find((m) => m.role === 'user');
    return `[mock-ai-response] Based only on the extracted label data: ${lastUser?.content.slice(0, 120) ?? ''}`;
  }
}
