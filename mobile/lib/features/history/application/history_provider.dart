import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';

/// Scan history, network-first with an offline fallback to the local cache (summarised from
/// cached full Scan objects, since the cache only stores complete scans, not list pages).
final scanHistoryProvider = FutureProvider<List<ScanSummary>>((ref) async {
  final repository = ref.watch(scansRepositoryProvider);
  final cache = ref.watch(scanCacheProvider);

  final result = await repository.listScans(limit: 50);

  final networkItems = result.when(ok: (page) => page.items, err: (_) => null);
  if (networkItems != null) return networkItems;

  final cached = await cache.getAll();
  return cached
      .map((s) => ScanSummary(
            scanId: s.scanId,
            status: s.status,
            productName: s.product?.name,
            brand: s.product?.brand,
            hasCriticalSafetyFlag: s.hasCriticalFlag,
            createdAt: s.createdAt,
          ))
      .toList();
});
