import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/settings_storage.dart';

class AppSettings extends Equatable {
  final bool hapticsEnabled;
  final bool cloudTtsFallbackEnabled;

  const AppSettings({this.hapticsEnabled = true, this.cloudTtsFallbackEnabled = true});

  AppSettings copyWith({bool? hapticsEnabled, bool? cloudTtsFallbackEnabled}) => AppSettings(
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        cloudTtsFallbackEnabled: cloudTtsFallbackEnabled ?? this.cloudTtsFallbackEnabled,
      );

  @override
  List<Object?> get props => [hapticsEnabled, cloudTtsFallbackEnabled];
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._storage, this._onCloudTtsChanged) : super(const AppSettings()) {
    _restore();
  }

  final SettingsStorage _storage;
  final void Function(bool enabled) _onCloudTtsChanged;

  Future<void> _restore() async {
    final haptics = await _storage.getHapticsEnabled();
    final cloudTts = await _storage.getCloudTtsFallbackEnabled();
    state = AppSettings(hapticsEnabled: haptics, cloudTtsFallbackEnabled: cloudTts);
    _onCloudTtsChanged(cloudTts);
  }

  Future<void> setHapticsEnabled(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await _storage.setHapticsEnabled(value);
  }

  Future<void> setCloudTtsFallbackEnabled(bool value) async {
    state = state.copyWith(cloudTtsFallbackEnabled: value);
    await _storage.setCloudTtsFallbackEnabled(value);
    _onCloudTtsChanged(value);
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  return SettingsController(ref.watch(settingsStorageProvider), (enabled) => tts.cloudFallbackEnabled = enabled);
});
