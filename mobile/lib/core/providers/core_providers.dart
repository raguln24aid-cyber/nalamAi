import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../accessibility/haptic_service.dart';
import '../accessibility/tts_service.dart';
import '../accessibility/voice_input_service.dart';
import '../auth/device_account.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../repositories/assistant_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/scans_repository.dart';
import '../repositories/tts_repository.dart';
import '../storage/scan_cache.dart';
import '../storage/secure_token_storage.dart';
import '../storage/settings_storage.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) => SecureTokenStorage());
final deviceAccountStoreProvider = Provider<DeviceAccountStore>((ref) => DeviceAccountStore());

/// Lets any screen know when it has been returned to (the screen above it was popped) so it can
/// speak itself again and re-arm its microphone — see HandsFreeLoopMixin. Without this a user
/// who comes back from a scan lands on a silent, deaf screen.
final routeObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
);
final settingsStorageProvider = Provider<SettingsStorage>((ref) => SettingsStorage());
final scanCacheProvider = Provider<ScanCache>((ref) => ScanCache());
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(secureTokenStorageProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));
final scansRepositoryProvider = Provider((ref) => ScansRepository(ref.watch(apiClientProvider)));
final assistantRepositoryProvider = Provider((ref) => AssistantRepository(ref.watch(apiClientProvider)));
final ttsRepositoryProvider = Provider((ref) => TtsRepository(ref.watch(apiClientProvider)));

final hapticServiceProvider = Provider<HapticService>((ref) {
  final service = HapticService();
  service.initialize();
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(ttsRepository: ref.watch(ttsRepositoryProvider));
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  final service = VoiceInputService();
  service.initialize();
  return service;
});

/// Live online/offline status, used by the offline banner and to gate scan/assistant actions.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});
