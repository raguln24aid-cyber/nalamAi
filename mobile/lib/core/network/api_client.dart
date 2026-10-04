import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_token_storage.dart';
import 'connectivity_service.dart';
import '../error/failure.dart';
import 'error_mapper.dart';

/// A handful of routes are unauthenticated or are the refresh call itself — never attach a
/// (possibly stale) access token or attempt a refresh loop on these.
const _noAuthPaths = ['/auth/login', '/auth/register', '/auth/refresh', '/health'];

/// Central HTTP client: attaches the access token, transparently refreshes it once on a 401
/// and retries, maps every failure to the app's typed [Failure], and fails fast with
/// [Failure.network] when the device is offline instead of waiting for a timeout.
class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    ConnectivityService? connectivityService,
    Dio? dio,
  })  : _tokenStorage = tokenStorage,
        _connectivity = connectivityService ?? ConnectivityService(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final ConnectivityService _connectivity;

  /// Set by the auth provider; called when a refresh attempt fails so the app can route back
  /// to the login screen and clear in-memory state.
  void Function()? onSessionExpired;

  Completer<bool>? _refreshInFlight;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!await _connectivity.isOnline) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'offline',
      ));
      return;
    }

    if (!_noAuthPaths.any((p) => options.path.startsWith(p))) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final isAuthEndpoint = _noAuthPaths.any((p) => error.requestOptions.path.startsWith(p));
    if (error.response?.statusCode != 401 || isAuthEndpoint) {
      handler.next(error);
      return;
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      onSessionExpired?.call();
      handler.next(error);
      return;
    }

    try {
      final retried = await _dio.fetch(error.requestOptions);
      handler.resolve(retried);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    if (_refreshInFlight != null) return _refreshInFlight!.future;

    final completer = Completer<bool>();
    _refreshInFlight = completer;

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }

      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      await _tokenStorage.updateTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
      completer.complete(true);
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }

  /// Runs [request] and converts any thrown error into a typed [Result], so repositories never
  /// need to catch Dio exceptions directly.
  Future<Result<T>> guard<T>(Future<T> Function(Dio dio) request) async {
    try {
      final value = await request(_dio);
      return Result.ok(value);
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }

  Dio get raw => _dio;
}
