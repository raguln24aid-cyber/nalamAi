import { prisma } from '../../lib/prisma';
import { notFound, AppError } from '../../lib/errors';
import { getAiProvider } from '../../providers';
import { AiProviderError } from '../../providers/ai.provider';
import { SCAN_INCLUDE } from '../products/dto';
import { buildSystemPrompt } from './prompt';
import { applySafetyFilter } from './safetyFilter';
import { stripMarkdown } from './markdownStrip';
import { resolveResponseLanguage } from './languageDetector';

const MAX_HISTORY_MESSAGES = 10;

export interface AssistantQueryInput {
  scanId: string;
  question: string;
  language?: 'en' | 'ta' | 'auto';
  compareScanId?: string;
}

export async function query(userId: string, input: AssistantQueryInput) {
  const scan = await prisma.scan.findUnique({ where: { id: input.scanId }, include: SCAN_INCLUDE });
  if (!scan || scan.userId !== userId) throw notFound('Scan');
  if (!scan.product) {
    throw new AppError('VALIDATION_ERROR', 'This scan has no resolved product to ask about yet');
  }

  let compareScan = null;
  if (input.compareScanId) {
    compareScan = await prisma.scan.findUnique({ where: { id: input.compareScanId }, include: SCAN_INCLUDE });
    if (!compareScan || compareScan.userId !== userId) throw notFound('Comparison scan');
  }

  const language = resolveResponseLanguage(input.language, input.question);
  const systemPrompt = buildSystemPrompt({ scan, compareScan, language });

  const history = await prisma.chatMessage.findMany({
    where: { scanId: input.scanId, userId },
    orderBy: { createdAt: 'desc' },
    take: MAX_HISTORY_MESSAGES,
  });

  const messages = [
    ...history.reverse().map((m) => ({ role: m.role, content: m.text })),
    { role: 'user' as const, content: input.question },
  ];

  const ai = getAiProvider();
  let rawAnswer: string;
  try {
    rawAnswer = await ai.complete({ systemPrompt, messages, maxTokens: 400 });
  } catch (err) {
    if (err instanceof AiProviderError) {
      throw new AppError('PROVIDER_UNAVAILABLE', 'The AI assistant is temporarily unavailable');
    }
    throw err;
  }

  const { text: answer, filtered } = applySafetyFilter(stripMarkdown(rawAnswer), language);

  await prisma.$transaction([
    prisma.chatMessage.create({
      data: { userId, scanId: input.scanId, role: 'user', text: input.question, language },
    }),
    prisma.chatMessage.create({
      data: { userId, scanId: input.scanId, role: 'assistant', text: answer, language },
    }),
  ]);

  return {
    answer,
    language,
    provenanceUsed: collectProvenance(scan),
    uncertain: filtered || answer.includes('could not be verified'),
  };
}

export async function getHistory(userId: string, scanId: string) {
  const scan = await prisma.scan.findUnique({ where: { id: scanId } });
  if (!scan || scan.userId !== userId) throw notFound('Scan');

  return prisma.chatMessage.findMany({
    where: { scanId, userId },
    orderBy: { createdAt: 'asc' },
  });
}

function collectProvenance(scan: { product: { nutritionFacts: { provenance: string } | null } | null }): string[] {
  const set = new Set<string>();
  if (scan.product?.nutritionFacts) set.add(scan.product.nutritionFacts.provenance);
  return Array.from(set);
}
