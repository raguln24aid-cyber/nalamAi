import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/locale_controller.dart';
import '../localization/generated/app_localizations.dart';
import '../providers/core_providers.dart';
import 'active_voice_screen.dart';
import 'global_voice_commands.dart';
import 'voice_input_service.dart';

/// Shared "speak, then listen, then act, then listen again" loop used by every screen so the
/// whole app stays hands-free after it's opened — not just Home/Scanner/Result/Assistant. Mix
/// this into a `ConsumerState` and call [startListening] after speaking a screen's content;
/// implement command handling in the [onFinalResult] callback you pass in.
///
/// Three things happen here that every screen needs and none should reimplement:
///
///  * **Global commands are handled first.** "go back", "go home", "help", "where am I",
///    "repeat" and "stop talking" are intercepted before the screen's own parser ever sees the
///    text, so they work identically everywhere (see [GlobalVoiceRouter]).
///  * **The loop re-arms when the user comes back.** A screen that was navigated away from and
///    returned to used to sit silent and deaf, stranding anyone who cannot see that the
///    microphone is off. [didPopNext] restarts it via [onScreenResumed].
///  * **Failures are spoken, not shown.** A microphone that will not start is announced aloud
///    and through haptics; a snackbar alone is invisible to this app's primary user.
///
/// [autoListenActive] mirrors each screen's own copy of "should we keep looping" — false after
/// the mic becomes unavailable (permission denied) or the user explicitly silences it via a
/// manual mic tap, so we never retry in a tight, noisy loop.
mixin HandsFreeLoopMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> implements RouteAware {
  bool isListening = false;
  bool autoListenActive = true;

  /// Consecutive listen sessions that ended without the user being understood. Bounded so a
  /// phone left face-down in a noisy room stops re-opening its microphone forever.
  int _unheardStreak = 0;
  static const _silentRetries = 3;
  static const _maxRetries = 6;

  RouteObserver<ModalRoute<void>>? _routeObserver;
  void Function(String text)? _lastOnFinalResult;
  Duration? _lastListenFor;
  Duration? _lastPauseFor;

  String get listenLanguage => ref.read(localeControllerProvider);
  String get spokenLanguage => listenLanguage == 'ta' ? 'ta' : 'en';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      _routeObserver?.unsubscribe(this);
      final observer = ref.read(routeObserverProvider);
      observer.subscribe(this, route);
      _routeObserver = observer;
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    ref.read(activeVoiceScreenProvider).unregister(this);
    super.dispose();
  }

  @override
  void didPopNext() => onScreenResumed();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {
    // Another screen is taking over the microphone and the speaker; release both so two
    // screens never listen or talk at once.
    autoListenActive = false;
    unawaitedStop();
  }

  /// Called when the user returns to this screen from one pushed on top of it. The default
  /// re-arms the microphone; override to also re-speak the screen's content first, then call
  /// `super.onScreenResumed()` or [startListening] yourself.
  void onScreenResumed() {
    autoListenActive = true;
    final onFinalResult = _lastOnFinalResult;
    if (onFinalResult != null) {
      startListening(
        onFinalResult: onFinalResult,
        listenFor: _lastListenFor,
        pauseFor: _lastPauseFor,
      );
    }
  }

  void unawaitedStop() {
    ref.read(voiceInputServiceProvider).stop();
    if (mounted) isListening = false;
  }

  /// Speaks [text], then opens the microphone once the audio has actually finished — speaking
  /// and listening at the same time makes the recognizer transcribe the app's own voice.
  Future<void> speakThenListen(
    String text, {
    required void Function(String text) onFinalResult,
    String? language,
  }) async {
    await ref.read(ttsServiceProvider).speak(text, language: language ?? spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: onFinalResult);
  }

  Future<void> startListening({
    required void Function(String text) onFinalResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!mounted) return;
    _lastOnFinalResult = onFinalResult;
    _lastListenFor = listenFor;
    _lastPauseFor = pauseFor;

    // Claim the app-wide "talk to me" gesture, so a double tap anywhere on screen reopens this
    // screen's microphone with this screen's vocabulary.
    ref.read(activeVoiceScreenProvider).register(this, () {
      autoListenActive = true;
      startListening(onFinalResult: onFinalResult, listenFor: listenFor, pauseFor: pauseFor);
    });

    final voiceInput = ref.read(voiceInputServiceProvider);
    await ref.read(hapticServiceProvider).tap();

    final status = await voiceInput.listen(
      language: listenLanguage,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onResult: (text, isFinal) {
        if (isFinal && text.trim().isNotEmpty) {
          _unheardStreak = 0;
          _dispatch(text, onFinalResult);
        }
      },
      onError: (errorMsg, permanent) => _handleListenError(errorMsg, onFinalResult),
    );

    if (!mounted) return;
    if (status == VoiceInputStatus.listening) {
      setState(() => isListening = true);
      if (voiceInput.consumeTamilFallbackNotice()) {
        ref
            .read(ttsServiceProvider)
            .speak(AppLocalizations.of(context).tamilSpeechUnavailableSpoken, language: 'ta');
      }
    } else {
      // Avoid re-prompting forever if the mic is unavailable/denied.
      autoListenActive = false;
      setState(() => isListening = false);
      await announceMicUnavailable(status);
    }
  }

  /// Recovers from a listen session that ended without hearing a usable command.
  ///
  /// `error_no_match` and `error_speech_timeout` end the session with no final result, so
  /// without this the microphone simply closes and the app is deaf until the user finds a
  /// button — which, for someone who cannot see the screen, means the app has stopped working.
  /// The first few retries are silent (the user may just be thinking, or a door slammed); after
  /// that we say so, so the silence is explained rather than mysterious; eventually we stop and
  /// tell them how to start again, rather than cycling the microphone indefinitely.
  Future<void> _handleListenError(String errorMsg, void Function(String text) onFinalResult) async {
    if (!mounted || !autoListenActive) return;
    if (!VoiceInputService.isRecoverableError(errorMsg)) return;

    _unheardStreak++;
    if (mounted) setState(() => isListening = false);

    if (_unheardStreak > _maxRetries) {
      autoListenActive = false;
      _unheardStreak = 0;
      await ref.read(hapticServiceProvider).warning();
      if (!mounted) return;
      await ref
          .read(ttsServiceProvider)
          .speak(AppLocalizations.of(context).voiceIdleStopped, language: spokenLanguage);
      return;
    }

    if (_unheardStreak == _silentRetries && mounted) {
      await ref
          .read(ttsServiceProvider)
          .speak(AppLocalizations.of(context).voiceNotUnderstood, language: spokenLanguage);
    }

    if (mounted && autoListenActive) await startListening(onFinalResult: onFinalResult);
  }

  /// Global commands win over the screen's own vocabulary, and a global command that does not
  /// navigate (help, repeat, where am I) hands the microphone straight back to the user.
  Future<void> _dispatch(String text, void Function(String text) onFinalResult) async {
    if (!mounted) return;
    var navigatedAway = false;

    final handled = await GlobalVoiceRouter(ref, context).handle(
      text,
      navigated: () {
        navigatedAway = true;
        autoListenActive = false;
      },
    );

    if (!handled) {
      onFinalResult(text);
      return;
    }
    if (!mounted || navigatedAway) return;
    if (autoListenActive) await startListening(onFinalResult: onFinalResult);
  }

  /// A failed microphone has to be audible and felt — the user cannot see a greyed-out button.
  Future<void> announceMicUnavailable(VoiceInputStatus status) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = status == VoiceInputStatus.permissionDenied
        ? l10n.permissionMicDenied
        : l10n.micUnavailableSpoken;

    await ref.read(hapticServiceProvider).warning();
    await ref.read(ttsServiceProvider).speak(message, language: spokenLanguage);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> stopListening() async {
    await ref.read(voiceInputServiceProvider).stop();
    if (mounted) setState(() => isListening = false);
  }

  /// Manual mic-button handler: tapping while listening silences the loop (until tapped again);
  /// tapping while idle resumes it. Every screen using this mixin should still expose a visible
  /// mic control for this — voice-first never means voice-only, per the accessibility spec.
  Future<void> toggleListening({required void Function(String text) onFinalResult}) async {
    if (isListening) {
      autoListenActive = false;
      await stopListening();
    } else {
      autoListenActive = true;
      await startListening(onFinalResult: onFinalResult);
    }
  }
}
