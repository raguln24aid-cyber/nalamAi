import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan.dart';

/// Local cache of recent scans so Product Result, Nutrition Details, Ingredients & Allergens,
/// and Scan History remain usable offline (see ARCHITECTURE.md "Offline" decision).
/// Bounded to the most recent [_maxEntries] scans to keep on-device storage small.
class ScanCache {
  ScanCache({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  static const _key = 'nalamai.cachedScans';
  static const _maxEntries = 50;

  Future<SharedPreferences> get _prefs async => _prefsOverride ?? SharedPreferences.getInstance();

  Future<void> upsert(Scan scan) async {
    final prefs = await _prefs;
    final scans = await getAll();
    final withoutExisting = scans.where((s) => s.scanId != scan.scanId).toList();
    final updated = [scan, ...withoutExisting].take(_maxEntries).toList();
    await prefs.setString(_key, jsonEncode(updated.map((s) => s.toJson()).toList()));
  }

  Future<List<Scan>> getAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Scan.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Scan?> getById(String scanId) async {
    final scans = await getAll();
    for (final scan in scans) {
      if (scan.scanId == scanId) return scan;
    }
    return null;
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_key);
  }
}
