import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/repositories/scans_repository.dart';
import '../../../core/storage/scan_cache.dart';

enum ScanSubmissionStatus { idle, submitting, success, failure }

class ScanSubmissionState extends Equatable {
  final ScanSubmissionStatus status;
  final Scan? scan;
  final Failure? failure;

  const ScanSubmissionState({required this.status, this.scan, this.failure});
  const ScanSubmissionState.idle() : this(status: ScanSubmissionStatus.idle);

  @override
  List<Object?> get props => [status, scan, failure];
}

/// Drives the "capture -> submit -> result" half of the scanning workflow. The live camera
/// guidance (blur/lighting/framing) lives in the Scanner screen itself, next to the
/// FrameQualityAnalyzer — this controller only owns what happens once a frame or barcode has
/// actually been captured and sent to the backend.
class ScanController extends StateNotifier<ScanSubmissionState> {
  ScanController(this._repository, this._cache) : super(const ScanSubmissionState.idle());

  final ScansRepository _repository;
  final ScanCache _cache;

  Future<void> submitImage(String imageBase64, {String languageHint = 'auto'}) async {
    state = const ScanSubmissionState(status: ScanSubmissionStatus.submitting);
    final result = await _repository.createScan(imageBase64: imageBase64, languageHint: languageHint);
    await _applyResult(result);
  }

  Future<void> submitBarcode(String barcode, {String languageHint = 'auto'}) async {
    state = const ScanSubmissionState(status: ScanSubmissionStatus.submitting);
    final result = await _repository.createScan(barcode: barcode, languageHint: languageHint);
    await _applyResult(result);
  }

  Future<void> _applyResult(Result<Scan> result) async {
    await result.when(
      ok: (scan) async {
        await _cache.upsert(scan);
        state = ScanSubmissionState(status: ScanSubmissionStatus.success, scan: scan);
      },
      err: (failure) async {
        state = ScanSubmissionState(status: ScanSubmissionStatus.failure, failure: failure);
      },
    );
  }

  void reset() => state = const ScanSubmissionState.idle();
}

final scanControllerProvider = StateNotifierProvider.autoDispose<ScanController, ScanSubmissionState>((ref) {
  return ScanController(ref.watch(scansRepositoryProvider), ref.watch(scanCacheProvider));
});
