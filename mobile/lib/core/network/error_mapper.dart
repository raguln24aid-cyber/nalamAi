import 'package:dio/dio.dart';
import '../error/failure.dart';

/// Translates any Dio failure (HTTP error body, timeout, no connection) into the app's
/// typed [Failure], using the stable error codes from docs/API_CONTRACTS.md when available.
Failure mapDioError(Object error) {
  if (error is! DioException) return Failure.unknown(error.toString());

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return Failure.network();
  }

  final data = error.response?.data;
  if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
    final errorBody = data['error'] as Map<String, dynamic>;
    return Failure(
      code: FailureCode.fromApiCode(errorBody['code'] as String?),
      message: errorBody['message'] as String? ?? 'Something went wrong.',
      details: errorBody['details'] as Map<String, dynamic>?,
    );
  }

  return Failure.unknown('Request failed with status ${error.response?.statusCode ?? 'unknown'}');
}
