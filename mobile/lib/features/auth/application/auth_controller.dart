import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/device_account.dart';
import '../../../core/error/failure.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../core/storage/settings_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final Failure? lastError;

  const AuthState({required this.status, this.user, this.lastError});

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  @override
  List<Object?> get props => [status, user, lastError];
}

/// Owns the app's auth session: rehydrates it on cold start, and drives login/register/logout.
/// A 401 that survives the ApiClient's own refresh attempt calls back here via
/// [ApiClient.onSessionExpired] to force the user back to the login screen.
class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._authRepository,
    this._tokenStorage,
    this._deviceAccounts,
    this._settings,
    this._apiClientOnSessionExpiredSetter,
  ) : super(const AuthState.unknown()) {
    _apiClientOnSessionExpiredSetter(_handleSessionExpired);
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final SecureTokenStorage _tokenStorage;
  final DeviceAccountStore _deviceAccounts;
  final SettingsStorage _settings;
  final void Function(void Function()) _apiClientOnSessionExpiredSetter;

  /// Cold start. A stored session wins; failing that, a device that already owns an account
  /// signs back into it silently, so a returning blind user never meets an auth screen at all.
  Future<void> _restoreSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final userJson = await _tokenStorage.readUserJson();
    if (accessToken != null && userJson != null) {
      state = AuthState(status: AuthStatus.authenticated, user: AppUser.fromJson(userJson));
      return;
    }

    if (await _settings.getSignedOutDeliberately()) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final credentials = await _deviceAccounts.read();
    if (credentials == null) {
      // First run: the welcome screen asks for consent out loud before creating anything.
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final signedIn = await login(email: credentials.email, password: credentials.password);
    if (!signedIn) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// The whole of sign-up and sign-in for a voice-only user: no address, no password, no
  /// keyboard. Registers this device's account the first time and signs into it every time
  /// after. Safe to call repeatedly — it is the single entry point the welcome screen and the
  /// "sign in" voice command both use.
  Future<bool> signInHandsFree() async {
    await _settings.setSignedOutDeliberately(false);
    final credentials = await _deviceAccounts.getOrCreate();

    // Register first for a brand-new account; if this device's account already exists on the
    // server (reinstall against the same backend, or a retry after the response was lost) the
    // conflict is expected and we just sign in instead.
    final registered = await register(
      email: credentials.email,
      password: credentials.password,
      preferredLanguage: await _settings.getLanguage(),
    );
    if (registered) return true;

    final failure = state.lastError;
    if (failure != null && failure.code == FailureCode.network) return false;

    return login(email: credentials.email, password: credentials.password);
  }

  void _handleSessionExpired() {
    _tokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    final result = await _authRepository.login(email: email, password: password);
    return result.when(
      ok: (session) {
        _tokenStorage.saveSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userJson: session.user.toJson(),
        );
        state = AuthState(status: AuthStatus.authenticated, user: session.user);
        return true;
      },
      err: (failure) {
        state = AuthState(status: AuthStatus.unauthenticated, lastError: failure);
        return false;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String preferredLanguage,
  }) async {
    final result = await _authRepository.register(
      email: email,
      password: password,
      preferredLanguage: preferredLanguage,
    );
    return result.when(
      ok: (session) {
        _tokenStorage.saveSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userJson: session.user.toJson(),
        );
        state = AuthState(status: AuthStatus.authenticated, user: session.user);
        return true;
      },
      err: (failure) {
        state = AuthState(status: AuthStatus.unauthenticated, lastError: failure);
        return false;
      },
    );
  }

  Future<void> logout() async {
    // Keep the device credentials: they are the only handle on this account and its history.
    // The flag is what stops _restoreSession signing the user straight back in.
    await _settings.setSignedOutDeliberately(true);
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      await _authRepository.logout(refreshToken: refreshToken);
    }
    await _tokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(secureTokenStorageProvider),
    ref.watch(deviceAccountStoreProvider),
    ref.watch(settingsStorageProvider),
    (callback) => apiClient.onSessionExpired = callback,
  );
});
