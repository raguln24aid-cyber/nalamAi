import 'package:equatable/equatable.dart';

/// Mirrors the backend's stable error codes — see docs/API_CONTRACTS.md.
enum FailureCode {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  extractionFailed,
  providerUnavailable,
  internal,
  network,
  unknown;

  static FailureCode fromApiCode(String? code) => switch (code) {
        'VALIDATION_ERROR' => FailureCode.validation,
        'UNAUTHORIZED' => FailureCode.unauthorized,
        'FORBIDDEN' => FailureCode.forbidden,
        'NOT_FOUND' => FailureCode.notFound,
        'CONFLICT' => FailureCode.conflict,
        'RATE_LIMITED' => FailureCode.rateLimited,
        'EXTRACTION_FAILED' => FailureCode.extractionFailed,
        'PROVIDER_UNAVAILABLE' => FailureCode.providerUnavailable,
        'INTERNAL_ERROR' => FailureCode.internal,
        _ => FailureCode.unknown,
      };
}

/// A typed failure carried through the app instead of raw exceptions, so the UI/TTS layer can
/// always render (and speak) something meaningful instead of a stack trace.
class Failure extends Equatable {
  final FailureCode code;
  final String message;
  final Map<String, dynamic>? details;

  const Failure({required this.code, required this.message, this.details});

  factory Failure.network() =>
      const Failure(code: FailureCode.network, message: 'No internet connection.');

  factory Failure.unknown([String? message]) =>
      Failure(code: FailureCode.unknown, message: message ?? 'Something went wrong.');

  String? get extractionReason => details?['reason'] as String?;

  @override
  List<Object?> get props => [code, message, details];
}

/// Simple Result type to force call sites to handle both success and failure explicitly,
/// rather than relying on uncaught exceptions to signal errors across layers.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.err(Failure failure) = Err<T>;

  R when<R>({required R Function(T value) ok, required R Function(Failure failure) err}) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    return err((self as Err<T>).failure);
  }

  bool get isOk => this is Ok<T>;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
