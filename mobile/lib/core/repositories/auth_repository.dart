import '../error/failure.dart';
import '../models/user.dart';
import '../network/api_client.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    String preferredLanguage = 'auto',
  }) {
    return _client.guard((dio) async {
      final res = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'preferredLanguage': preferredLanguage,
      });
      return AuthSession.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<AuthSession>> login({required String email, required String password}) {
    return _client.guard((dio) async {
      final res = await dio.post('/auth/login', data: {'email': email, 'password': password});
      return AuthSession.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<Result<void>> logout({required String refreshToken}) {
    return _client.guard((dio) async {
      await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    });
  }
}
