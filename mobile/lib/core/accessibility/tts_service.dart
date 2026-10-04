import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import '../repositories/tts_repository.dart';

const _localeByLanguage = {'en': 'en-IN', 'ta': 'ta-IN'};

/// Text-to-speech for the audio-response layer (product spec section 8). Tries on-device
/// synthesis first (fast, free, works offline); if the device has no usable voice for the
/// requested language, falls back to the backend-proxied cloud TTS (see TtsRepository) when
/// the caller has cloud fallback enabled. Every provider credential lives server-side only.
class TtsService {
  TtsService({required TtsRepository ttsRepository, FlutterTts? flutterTts, AudioPlayer? audioPlayer})
      : _ttsRepository = ttsRepository,
        _flutterTts = flutterTts ?? FlutterTts(),
        _audioPlayer = audioPlayer ?? AudioPlayer();

  final TtsRepository _ttsRepository;
  final FlutterTts _flutterTts;
  final AudioPlayer _audioPlayer;
  final _log = Logger('TtsService');

  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get isSpeakingStream => _speakingController.stream;
  bool isSpeaking = false;

  bool cloudFallbackEnabled = true;

  /// Bumped by every [speak]. Lets an utterance tell "I was cut off because a newer utterance
  /// started" apart from "this device cannot say this", which look identical from the return
  /// code and must be handled completely differently.
  int _speechGeneration = 0;
  Set<String> _deviceLanguages = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _flutterTts.setStartHandler(() => _setSpeaking(true));
    _flutterTts.setCompletionHandler(() => _setSpeaking(false));
    _flutterTts.setCancelHandler(() => _setSpeaking(false));
    _flutterTts.setErrorHandler((msg) {
      _log.warning('flutter_tts error: $msg');
      _setSpeaking(false);
    });
    // Without this, `await speak(...)` returns as soon as the platform call is dispatched, not
    // when the audio actually finishes — which breaks any "speak this, then listen" sequencing
    // (e.g. auto-listening right after the Home greeting, or after a scan-result summary).
    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      _log.warning('awaitSpeakCompletion not supported on this platform: $e');
    }

    try {
      final languages = await _flutterTts.getLanguages;
      _deviceLanguages = (languages as List<dynamic>).map((e) => e.toString()).toSet();
      // Which voices a device actually ships with varies enormously and decides whether the
      // app speaks locally or needs the network — worth one line at startup when diagnosing a
      // silent or unexpectedly slow device.
      _log.info('Device TTS languages: ${_deviceLanguages.toList()..sort()}');
    } catch (e) {
      _log.warning('Could not query device TTS languages: $e');
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) _setSpeaking(false);
    });
  }

  void _setSpeaking(bool value) {
    isSpeaking = value;
    _speakingController.add(value);
  }

  /// On-device voices to try for [language], best first.
  ///
  /// `getLanguages` reports what the engine *supports*, which is not the same as what it can
  /// actually speak: Google's engine advertises ~80 locales while shipping voice data for only
  /// a few, so `en-IN` can be listed and still fail. That is exactly what happened on the first
  /// real device we ran this on — `speak` returned 0 and every utterance silently fell through
  /// to the network. Hence a list rather than a single choice: try the regional voice, then any
  /// other region of the same language, checking each is genuinely installed, and only give up
  /// to the cloud once none of them works.
  List<String> _deviceLocaleCandidates(String language) {
    final preferred = (_localeByLanguage[language] ?? 'en-IN').toLowerCase();
    final available = {
      for (final l in _deviceLanguages) l.replaceAll('_', '-').toLowerCase(): l,
    };

    final candidates = <String>[];
    final exact = available[preferred];
    if (exact != null) candidates.add(exact);

    final prefix = '${language.toLowerCase()}-';
    for (final entry in available.entries) {
      final sameLanguage = entry.key == language.toLowerCase() || entry.key.startsWith(prefix);
      if (sameLanguage && !candidates.contains(entry.value)) candidates.add(entry.value);
    }
    return candidates;
  }

  /// Returns true only if the words actually made it to the speaker.
  Future<bool> _trySpeakOnDevice(String text, String locale) async {
    try {
      final installed = await _flutterTts.isLanguageInstalled(locale);
      if (installed != true) {
        _log.info('TTS voice data for "$locale" is not installed; trying the next candidate');
        return false;
      }
    } catch (e) {
      // Not implemented on this platform — fall through and let speak() be the judge.
      _log.fine('isLanguageInstalled unavailable for "$locale": $e');
    }

    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(1.0);
    final result = await _flutterTts.speak(text);
    if (result == 1) return true; // 1 == success per flutter_tts contract

    _log.warning('On-device TTS refused "$locale" (code $result)');
    return false;
  }

  String? lastSpokenText;
  String lastSpokenLanguage = 'en';

  /// Re-speaks the most recent utterance — backs the "repeat" / "மீண்டும் சொல்" voice command.
  Future<void> repeatLast() async {
    final text = lastSpokenText;
    if (text != null) await speak(text, language: lastSpokenLanguage);
  }

  /// Speaks [text] in [language] ('en' or 'ta'). Cancels any in-progress speech first so
  /// guidance/answers never overlap and confuse a user who cannot see the screen.
  Future<void> speak(String text, {required String language}) async {
    if (text.trim().isEmpty) return;

    final generation = ++_speechGeneration;
    await stop();
    if (generation != _speechGeneration) return; // superseded while we were stopping

    lastSpokenText = text;
    lastSpokenLanguage = language;

    final candidates = _deviceLocaleCandidates(language);
    _log.info('speak("$language"): trying on-device voices $candidates');

    for (final locale in candidates) {
      final spoke = await _trySpeakOnDevice(text, locale);
      if (spoke) return;

      // A newer utterance replaced this one. flutter_tts reports that interruption with the
      // same failure code as a genuine refusal, so without this check a perfectly working
      // device looks broken and every interrupted line escalates to the network.
      if (generation != _speechGeneration) {
        _log.info('speak("$language") superseded by a newer utterance; not falling back');
        return;
      }
    }

    if (!cloudFallbackEnabled) {
      _log.warning('No on-device voice for "$language" and cloud fallback is disabled');
      return;
    }

    _log.warning('No on-device voice worked for "$language"; falling back to cloud TTS');
    await _speakViaCloudFallback(text, language);
  }

  Future<void> _speakViaCloudFallback(String text, String language) async {
    _setSpeaking(true);
    final result = await _ttsRepository.synthesize(text: text, language: language);
    await result.when(
      ok: (bytes) async {
        try {
          await _audioPlayer.setAudioSource(_BytesAudioSource(bytes));
          await _audioPlayer.play();
          // play() dispatches playback but doesn't wait for it to finish — block here so
          // callers can reliably sequence "speak, then do X" (see initialize()'s comment).
          await _audioPlayer.playerStateStream.firstWhere(
            (s) => s.processingState == ProcessingState.completed,
          );
        } catch (e) {
          _log.severe('Cloud TTS playback failed: $e');
        } finally {
          _setSpeaking(false);
        }
      },
      err: (failure) async {
        _log.severe('Cloud TTS request failed: ${failure.message}');
        _setSpeaking(false);
      },
    );
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
    _setSpeaking(false);
  }

  Future<void> dispose() async {
    await _speakingController.close();
    await _audioPlayer.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes);
  final List<int> _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
