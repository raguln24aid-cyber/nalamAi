import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/profile.dart';
import '../../../core/providers/core_providers.dart';

/// The server-side profile (allergies, dietary preference/restrictions) — the single source of
/// truth used for allergen safety comparisons. Invalidate this provider after any mutation
/// (see AllergyDietPreferencesScreen) so every screen reading it refetches.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).getProfile();
  return result.when(ok: (profile) => profile, err: (_) => null);
});
