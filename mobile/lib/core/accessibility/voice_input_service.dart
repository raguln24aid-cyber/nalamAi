import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceInputStatus { idle, listening, notAvailable, permissionDenied, error }

const _localeCandidates = {
  'en': ['en_IN', 'en_US', 'en_GB'],
  'ta': ['ta_IN'],
};

/// Wraps `speech_to_text` for the voice-input half of the accessibility layer. Tamil on-device
/// recognition availability varies by device (it depends on the OS/Google app language pack
/// being installed) — [supportsTamil] lets the UI tell the user up front instead of failing
/// silently mid-command.
class VoiceInputService {
  VoiceInputService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  final _log = Logger('VoiceInputService');

  bool _initialized = false;
  List<LocaleName> _locales = [];

  /// True once the microphone has been refused in a way the app cannot re-prompt for, so the
  /// UI can send the user to system settings rather than asking again and again.
  bool permissionPermanentlyDenied = false;

  /// Called when the recognizer gives up on the current listen session. Crucial for a
  /// hands-free app: `error_no_match` and `error_speech_timeout` end the session without ever
  /// producing a final result, so a caller waiting only on `onResult` waits forever and the
  /// app goes quietly deaf. See HandsFreeLoopMixin, which re-arms on these.
  void Function(String errorMsg, bool permanent)? _onSessionError;

  /// Set when a Tamil listen had to fall back to the device default recognizer because no
  /// Tamil pack is installed. The UI reads this once to explain the switch out loud — silently
  /// listening in the wrong language would just look like the app ignoring the user.
  bool tamilFallbackApplied = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    // speech_to_text prompts for the microphone itself, but only reports a flat false when the
    // answer is no. Asking here first lets us tell "not yet granted" from "permanently denied",
    // which are two completely different things to say to someone who cannot see a dialog.
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      permissionPermanentlyDenied = permission.isPermanentlyDenied;
      _log.warning('Microphone permission not granted: $permission');
      return false;
    }

    final available = await _speech.initialize(
      onError: (e) {
        _log.warning('STT error: ${e.errorMsg} (permanent: ${e.permanent})');
        _onSessionError?.call(e.errorMsg, e.permanent);
      },
      onStatus: (s) => _log.fine('STT status: $s'),
    );
    _initialized = available;
    if (available) {
      _locales = await _speech.locales();
    }
    return available;
  }

  bool get supportsTamil => _bestLocaleFor('ta') != null;

  String? _bestLocaleFor(String language) {
    final candidates = _localeCandidates[language] ?? const [];
    for (final candidate in candidates) {
      final match = _locales.where((l) => l.localeId.replaceAll('-', '_') == candidate);
      if (match.isNotEmpty) return match.first.localeId;
    }
    return null;
  }

  /// Starts listening. [language] is 'en', 'ta', or 'auto' (device default locale is used for
  /// 'auto' since on-device recognizers do not support live language auto-detection —
  /// server-side text is still auto-detected per-request, see languageDetector.ts on the
  /// backend and the Tanglish note in core/accessibility/language_hint.dart).
  ///
  /// A Tamil request on a device with no Tamil pack falls back to the device default recognizer
  /// and raises [tamilFallbackApplied] rather than refusing to listen: a user who cannot see
  /// the screen has no other way in, and Tamil speakers in this app routinely mix in English
  /// product words anyway, so the default recognizer is far better than silence.
  ///
  /// [listenFor]/[pauseFor] bound how long this session stays open — used to implement brief
  /// "is the user trying to interrupt?" listening windows between spoken segments (see
  /// ProductResultScreen), as opposed to a normal open-ended command listen.
  Future<VoiceInputStatus> listen({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    void Function(String errorMsg, bool permanent)? onError,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_initialized && !await initialize()) {
      return permissionPermanentlyDenied
          ? VoiceInputStatus.permissionDenied
          : VoiceInputStatus.notAvailable;
    }

    _onSessionError = onError;

    String? localeId;
    if (language != 'auto') {
      localeId = _bestLocaleFor(language);
      if (language == 'ta' && localeId == null) tamilFallbackApplied = true;
    }

    try {
      await _speech.listen(
        onResult: (result) => onResult(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
        ),
      );
      return VoiceInputStatus.listening;
    } on Object catch (e) {
      _log.severe('Failed to start listening: $e');
      return VoiceInputStatus.error;
    }
  }

  /// Reads and clears [tamilFallbackApplied], so the explanation is spoken once per fallback
  /// rather than before every single command.
  bool consumeTamilFallbackNotice() {
    if (!tamilFallbackApplied) return false;
    tamilFallbackApplied = false;
    return true;
  }

  Future<void> stop() {
    _onSessionError = null;
    return _speech.stop();
  }

  Future<void> cancel() {
    _onSessionError = null;
    return _speech.cancel();
  }

  /// Errors that mean "nobody said anything I could use" rather than "the microphone is
  /// broken" — worth silently listening again instead of giving up on the user.
  static bool isRecoverableError(String errorMsg) => const {
        'error_no_match',
        'error_speech_timeout',
        'error_retry',
        'error_client',
      }.contains(errorMsg);
  bool get isListening => _speech.isListening;
}
