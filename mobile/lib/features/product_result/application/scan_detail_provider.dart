import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';

/// Loads a single scan by id, preferring the network (freshest data) but transparently falling
/// back to the local cache when offline or the request fails — this is what keeps Product
/// Result / Nutrition Details / Ingredients & Allergens usable offline for previously-viewed
/// scans, per ARCHITECTURE.md.
final scanDetailProvider = FutureProvider.family<Scan?, String>((ref, scanId) async {
  final cache = ref.watch(scanCacheProvider);
  final repository = ref.watch(scansRepositoryProvider);

  final result = await repository.getScan(scanId);
  return result.when(
    ok: (scan) {
      cache.upsert(scan);
      return scan;
    },
    err: (_) => cache.getById(scanId),
  );
});
