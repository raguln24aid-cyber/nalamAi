import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../settings/application/locale_controller.dart';
import '../application/scan_controller.dart';
import '../domain/frame_quality_analyzer.dart';

enum _ScanMode { label, barcode }

const _captureKeywords = ['capture', 'take photo', 'take picture', 'take the photo', 'snap', 'படம் எடு', 'புகைப்படம்'];
const _barcodeModeKeywords = ['barcode', 'bar code', 'பார்கோடு'];
const _labelModeKeywords = ['photo mode', 'label mode', 'picture mode'];
const _waitKeywords = ['wait', 'not yet', 'hold on', 'do not capture', 'manual', 'பொறு', 'இன்னும் இல்லை'];
const _autoCaptureOnKeywords = ['automatic', 'auto capture', 'capture automatically', 'தானாக'];

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, HandsFreeLoopMixin<ScannerScreen> {
  _ScanMode _mode = _ScanMode.label;
  CameraController? _cameraController;
  MobileScannerController? _barcodeController;
  final _frameAnalyzer = FrameQualityAnalyzer();

  FrameGuidance _guidance = FrameGuidance.none;
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  bool _isCapturing = false;
  bool _barcodeHandled = false;
  DateTime _lastFrameAnalyzedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGuidanceSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  FrameGuidance? _lastSpokenGuidance;

  /// When the framing first became good, and when we last took a shot. Together these drive
  /// auto-capture: the user cannot see the preview, so "hold it there and say capture" asks
  /// them to judge a moment they have no way of perceiving.
  DateTime? _goodFramingSince;
  DateTime _lastCaptureAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _autoCaptureEnabled = true;

  /// How long the framing must stay good before the shutter fires — long enough that a frame
  /// that happened to look sharp while the phone swung past a label does not trigger it.
  static const _autoCaptureHold = Duration(milliseconds: 1200);

  /// Breathing room after a shot so a failed scan cannot immediately fire another one, which
  /// would leave the user unable to get a word in.
  static const _autoCaptureCooldown = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(ttsServiceProvider).speak(l10n.scannerInstructions, language: _currentLanguage());

    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      await ref.read(ttsServiceProvider).speak(l10n.permissionCameraDenied, language: _currentLanguage());
      return;
    }

    await _startLabelCamera();
    if (mounted && autoListenActive) {
      await startListening(onFinalResult: _handleScannerVoiceCommand);
    }
  }

  /// Voice commands available on the scanner itself — "capture"/"take photo" (label mode),
  /// "barcode"/"photo mode" to switch modes, plus the universal back/home. Barcode capture
  /// already happens automatically the moment one is detected (see [_onBarcodeDetect]), so this
  /// is mainly what makes taking a label photo possible without touching the screen.
  Future<void> _handleScannerVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final lower = text.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);

    if (CommonVoiceCommands.isBack(text)) {
      if (context.canPop()) context.pop();
      return;
    }
    if (CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (_barcodeModeKeywords.any(lower.contains)) {
      await _switchMode(_ScanMode.barcode);
    } else if (_labelModeKeywords.any(lower.contains)) {
      await _switchMode(_ScanMode.label);
    } else if (_waitKeywords.any(lower.contains)) {
      _autoCaptureEnabled = false;
      _goodFramingSince = null;
      await ref.read(ttsServiceProvider).speak(l10n.scannerAutoCaptureOff, language: _currentLanguage());
    } else if (_autoCaptureOnKeywords.any(lower.contains)) {
      _autoCaptureEnabled = true;
      await ref.read(ttsServiceProvider).speak(l10n.scannerAutoCaptureOn, language: _currentLanguage());
    } else if (_captureKeywords.any(lower.contains) && _mode == _ScanMode.label) {
      await _capture();
      return; // _capture() restarts the voice loop itself once it's done
    }

    if (mounted && autoListenActive) {
      await startListening(onFinalResult: _handleScannerVoiceCommand);
    }
  }

  String _currentLanguage() {
    final lang = ref.read(localeControllerProvider);
    return lang == 'ta' ? 'ta' : 'en';
  }

  Future<void> _startLabelCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        // veryHigh (~1080p) rather than medium (~720p) — OCR accuracy on small printed label
        // text benefits noticeably from the extra resolution, and a 1080p JPEG still comfortably
        // fits under the backend's 6MB per-image limit (see extraction.service.ts).
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
      await controller.startImageStream(_onCameraFrame);
    } catch (_) {
      // Camera hardware unavailable/in use — surfaced via the missing preview + retry button.
    }
  }

  Future<void> _stopLabelCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
  }

  void _onCameraFrame(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastFrameAnalyzedAt) < const Duration(milliseconds: 400)) return;
    _lastFrameAnalyzedAt = now;

    final result = _frameAnalyzer.analyzeCameraImage(image);
    if (result == null || !mounted) return;

    if (result.guidance != _guidance) {
      setState(() => _guidance = result.guidance);
    }
    _maybeSpeakGuidance(result.guidance);
    _trackGoodFraming(result.guidance);
  }

  /// Announces the moment the label is properly framed and then takes the picture.
  ///
  /// This is the difference between a scanner a blind user can operate and one they cannot.
  /// Previously the app fell silent once framing was good and waited to be told "capture" — but
  /// knowing that the label is centred, lit and sharp is precisely the judgement the user
  /// cannot make. Now the app says so, holds for [_autoCaptureHold] to be sure the framing is
  /// steady rather than a lucky frame in passing, and fires the shutter itself. Saying
  /// "capture" still works, and "wait" turns this off for people who would rather choose.
  void _trackGoodFraming(FrameGuidance guidance) {
    if (guidance != FrameGuidance.good) {
      _goodFramingSince = null;
      return;
    }
    if (_isCapturing || _mode != _ScanMode.label) return;

    final now = DateTime.now();
    if (now.difference(_lastCaptureAt) < _autoCaptureCooldown) return;

    if (_goodFramingSince == null) {
      _goodFramingSince = now;
      final l10n = AppLocalizations.of(context);
      ref.read(hapticServiceProvider).infoNotice();
      ref.read(ttsServiceProvider).speak(l10n.guidanceReadyToCapture, language: _currentLanguage());
      return;
    }

    if (_autoCaptureEnabled && now.difference(_goodFramingSince!) >= _autoCaptureHold) {
      _goodFramingSince = null;
      _capture();
    }
  }

  void _maybeSpeakGuidance(FrameGuidance guidance) {
    if (guidance == FrameGuidance.none || _isCapturing) return;
    final now = DateTime.now();
    final sameAsLast = guidance == _lastSpokenGuidance;
    final debounce = sameAsLast ? const Duration(seconds: 4) : const Duration(milliseconds: 800);
    if (now.difference(_lastGuidanceSpokenAt) < debounce) return;

    final l10n = AppLocalizations.of(context);
    final message = switch (guidance) {
      FrameGuidance.tooDark => l10n.guidanceTooDark,
      FrameGuidance.tooBright => l10n.guidanceTooBright,
      FrameGuidance.tooBlurry => l10n.guidanceTooBlurry,
      FrameGuidance.good => null, // silence once framing is good — don't nag
      FrameGuidance.none => null,
    };
    if (message == null) return;

    _lastGuidanceSpokenAt = now;
    _lastSpokenGuidance = guidance;
    ref.read(ttsServiceProvider).speak(message, language: _currentLanguage());
  }

  Future<void> _capture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) return;

    await stopListening(); // free the mic while capturing/uploading — nothing to listen for yet
    if (!mounted) return;
    setState(() => _isCapturing = true);
    _lastCaptureAt = DateTime.now();
    _goodFramingSince = null;
    final l10n = AppLocalizations.of(context);
    await ref.read(hapticServiceProvider).tap();
    await ref.read(ttsServiceProvider).speak(l10n.guidanceCapturing, language: _currentLanguage());

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final language = ref.read(localeControllerProvider);
      await ref.read(scanControllerProvider.notifier).submitImage(base64Image, languageHint: language);
    } finally {
      // Restart the cooldown from when the upload finished, not when it started — otherwise a
      // slow round trip lets the next auto-capture fire the instant this one returns.
      _lastCaptureAt = DateTime.now();
      if (mounted) setState(() => _isCapturing = false);
      if (mounted && _cameraController != null && !_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream(_onCameraFrame);
      }
      // Only resume listening if the scan didn't already navigate away on success — checked via
      // `mounted`, which go_router's pushReplacement flips false for this screen.
      if (mounted && autoListenActive) {
        await startListening(onFinalResult: _handleScannerVoiceCommand);
      }
    }
  }

  Future<void> _switchMode(_ScanMode mode) async {
    if (mode == _mode) return;
    if (mode == _ScanMode.barcode) {
      await _stopLabelCamera();
      _barcodeController = MobileScannerController(formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE]);
      _barcodeHandled = false;
    } else {
      await _barcodeController?.dispose();
      _barcodeController = null;
      await _startLabelCamera();
    }
    if (mounted) setState(() => _mode = mode);
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    if (_barcodeHandled) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;
    _barcodeHandled = true;

    final l10n = AppLocalizations.of(context);
    await ref.read(hapticServiceProvider).tap();
    await ref.read(ttsServiceProvider).speak(l10n.guidanceBarcodeDetected, language: _currentLanguage());
    await _barcodeController?.stop();

    final language = ref.read(localeControllerProvider);
    await ref.read(scanControllerProvider.notifier).submitBarcode(value, languageHint: language);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopLabelCamera();
    } else if (state == AppLifecycleState.resumed && _mode == _ScanMode.label) {
      _startLabelCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLabelCamera();
    _barcodeController?.dispose();
    super.dispose();
  }

  void _handleScanResult(ScanSubmissionState state) {
    final l10n = AppLocalizations.of(context);
    if (state.status == ScanSubmissionStatus.success && state.scan != null) {
      context.pushReplacement(AppRoutes.resultPath(state.scan!.scanId));
      return;
    }
    if (state.status == ScanSubmissionStatus.failure && state.failure != null) {
      final reason = ExtractionFailureReason.fromJson(state.failure!.extractionReason);
      final message = switch (reason) {
        ExtractionFailureReason.noTextDetected => l10n.guidanceNoTextFound,
        ExtractionFailureReason.barcodeNotFound => l10n.guidanceNoTextFound,
        ExtractionFailureReason.imageTooBlurry => l10n.guidanceTooBlurry,
        ExtractionFailureReason.providerError => l10n.errorGeneric,
        ExtractionFailureReason.unknown => state.failure!.message,
      };
      ref.read(ttsServiceProvider).speak(message, language: _currentLanguage());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _barcodeHandled = false;
      ref.read(scanControllerProvider.notifier).reset();
      if (mounted && autoListenActive && !isListening) {
        startListening(onFinalResult: _handleScannerVoiceCommand);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submissionState = ref.watch(scanControllerProvider);

    ref.listen<ScanSubmissionState>(scanControllerProvider, (previous, next) {
      if (previous?.status != next.status) _handleScanResult(next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.scannerTitle),
        actions: [
          IconButton(
            onPressed: () => toggleListening(onFinalResult: _handleScannerVoiceCommand),
            tooltip: isListening ? l10n.micListeningLabel : l10n.micIdleLabel,
            icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.redAccent : Colors.white),
          ),
          TextButton.icon(
            onPressed: () => _switchMode(_mode == _ScanMode.label ? _ScanMode.barcode : _ScanMode.label),
            icon: Icon(_mode == _ScanMode.label ? Icons.qr_code_scanner : Icons.camera_alt,
                color: Colors.white),
            label: Text(
              _mode == _ScanMode.label ? l10n.switchToBarcodeMode : l10n.switchToLabelMode,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          if (submissionState.status == ScanSubmissionStatus.submitting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(l10n.loading, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: _buildGuidancePanel(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_permissionChecked) return const Center(child: CircularProgressIndicator());
    if (!_permissionGranted) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.permissionCameraDenied, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
        ),
      );
    }

    if (_mode == _ScanMode.barcode && _barcodeController != null) {
      return MobileScanner(controller: _barcodeController, onDetect: _onBarcodeDetect);
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return CameraPreview(controller);
  }

  Widget _buildGuidancePanel(AppLocalizations l10n) {
    final guidanceText = switch (_guidance) {
      FrameGuidance.tooDark => l10n.guidanceTooDark,
      FrameGuidance.tooBright => l10n.guidanceTooBright,
      FrameGuidance.tooBlurry => l10n.guidanceTooBlurry,
      FrameGuidance.good => l10n.guidanceHoldSteady,
      FrameGuidance.none => l10n.scannerInstructions,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              guidanceText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_mode == _ScanMode.label)
          Semantics(
            button: true,
            label: l10n.captureButtonLabel,
            child: GestureDetector(
              onTap: _isCapturing ? null : _capture,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black26, width: 4),
                ),
                child: _isCapturing
                    ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                    : const Icon(Icons.camera_alt, size: 36, color: Colors.black87),
              ),
            ),
          ),
      ],
    );
  }
}
