export interface AiChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface AiCompletionRequest {
  systemPrompt: string;
  messages: AiChatMessage[];
  maxTokens?: number;
}

export class AiProviderError extends Error {}

/** Abstraction over any LLM backend used for the AI Food Assistant (AI_PROVIDER env var). */
export interface AiProvider {
  complete(request: AiCompletionRequest): Promise<string>;
}
