import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/language_hint.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../settings/application/locale_controller.dart';
import '../../../shared/widgets/big_mic_button.dart';
import '../../../shared/widgets/offline_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// Home is where a blind user starts and, crucially, where they land again after every scan.
/// It now runs on [HandsFreeLoopMixin], which buys three things it used to lack: the global
/// vocabulary ("help", "where am I", "go back") works here too, the microphone comes back on
/// when the user returns from another screen, and a microphone that fails to start says so out
/// loud instead of flashing a snackbar nobody can read.
class _HomeScreenState extends ConsumerState<HomeScreen> with HandsFreeLoopMixin {
  bool _spokenWelcome = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_spokenWelcome) {
      _spokenWelcome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runVoiceFirstEntry());
    }
  }

  /// The core "everything must be voice" entry point: speak the greeting, then — without
  /// requiring any tap — start listening immediately, so a blind user can act on the very
  /// first voice command right after opening the app.
  Future<void> _runVoiceFirstEntry() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await speakThenListen(
      '${l10n.welcomeSpoken} ${l10n.homeInstructions}',
      onFinalResult: _handleVoiceCommand,
      language: _greetingLanguage(l10n.welcomeSpoken),
    );
  }

  /// Coming back from a scan, the full welcome would be tedious on every return — a short
  /// re-orientation plus an open microphone is what the user actually needs.
  @override
  void onScreenResumed() {
    if (!mounted) return;
    autoListenActive = true;
    final l10n = AppLocalizations.of(context);
    speakThenListen(l10n.homeInstructions, onFinalResult: _handleVoiceCommand);
  }

  String _greetingLanguage(String text) {
    final setting = ref.read(localeControllerProvider);
    return setting == 'auto' ? LanguageHint.detect(text) : setting;
  }

  /// Only speech the global layer did not already claim reaches here — navigation, help,
  /// repeat and "where am I" are handled by the mixin before this runs.
  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);

    final l10n = AppLocalizations.of(context);
    final command = VoiceCommandParser.parse(text);
    final language = _greetingLanguage(text);

    final reply = switch (command) {
      // There is nothing to ask about until something has been scanned, so say what to do
      // rather than opening an assistant with no product loaded.
      VoiceCommand.askAssistant => '${l10n.assistantHint} ${l10n.helpHome}',
      _ => '${l10n.voiceNotUnderstood} ${l10n.helpHome}',
    };

    await ref.read(ttsServiceProvider).speak(reply, language: language);

    // Loop back to listening so the whole Home interaction stays hands-free, not just the
    // first command.
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.goToSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.homeInstructions,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 40),
                    BigMicButton(
                      isListening: isListening,
                      onPressed: () => toggleListening(onFinalResult: _handleVoiceCommand),
                      idleLabel: l10n.micIdleLabel,
                      listeningLabel: l10n.micListeningLabel,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isListening ? l10n.micListeningLabel : l10n.micIdleLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.scanner),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.scanButtonLabel),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.homeQuickActions, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.history),
                          icon: const Icon(Icons.history),
                          label: Text(l10n.goToHistory),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.profile),
                          icon: const Icon(Icons.person_outline),
                          label: Text(l10n.goToProfile),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
