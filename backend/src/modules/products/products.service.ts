import { prisma } from '../../lib/prisma';
import { notFound, AppError } from '../../lib/errors';
import { SCAN_INCLUDE, toScanDto, toScanSummaryDto } from './dto';

export async function listScans(userId: string, limit: number, cursor?: string) {
  const scans = await prisma.scan.findMany({
    where: { userId },
    include: SCAN_INCLUDE,
    orderBy: { createdAt: 'desc' },
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
  });

  const hasMore = scans.length > limit;
  const page = hasMore ? scans.slice(0, limit) : scans;

  return {
    items: page.map(toScanSummaryDto),
    nextCursor: hasMore ? page[page.length - 1]!.id : null,
  };
}

export async function getScan(userId: string, scanId: string) {
  const scan = await prisma.scan.findUnique({ where: { id: scanId }, include: SCAN_INCLUDE });
  if (!scan || scan.userId !== userId) throw notFound('Scan');
  return toScanDto(scan);
}

export async function compareScans(userId: string, scanIdA: string, scanIdB: string) {
  const [scanA, scanB] = await Promise.all([
    prisma.scan.findUnique({ where: { id: scanIdA }, include: SCAN_INCLUDE }),
    prisma.scan.findUnique({ where: { id: scanIdB }, include: SCAN_INCLUDE }),
  ]);

  if (!scanA || scanA.userId !== userId) throw notFound('Scan A');
  if (!scanB || scanB.userId !== userId) throw notFound('Scan B');
  if (!scanA.product || !scanB.product) {
    throw new AppError('VALIDATION_ERROR', 'Both scans must have a resolved product to compare');
  }

  const differences: { field: string; a: number | null; b: number | null; note: string }[] = [];
  const nfA = scanA.product.nutritionFacts;
  const nfB = scanB.product.nutritionFacts;

  const fields: { key: 'calories' | 'sugarG' | 'proteinG' | 'fatG' | 'saturatedFatG' | 'sodiumMg' | 'fiberG'; label: string }[] = [
    { key: 'calories', label: 'calories' },
    { key: 'sugarG', label: 'sugar' },
    { key: 'proteinG', label: 'protein' },
    { key: 'fatG', label: 'fat' },
    { key: 'saturatedFatG', label: 'saturated fat' },
    { key: 'sodiumMg', label: 'sodium' },
    { key: 'fiberG', label: 'fibre' },
  ];

  for (const field of fields) {
    const a = nfA?.[field.key] ?? null;
    const b = nfB?.[field.key] ?? null;
    if (a === null || b === null || a === b) continue;
    const higher = a > b ? 'A' : 'B';
    differences.push({
      field: field.key,
      a,
      b,
      note: `Product ${higher} has more ${field.label} per serving.`,
    });
  }

  return {
    a: toScanDto(scanA),
    b: toScanDto(scanB),
    differences,
  };
}
