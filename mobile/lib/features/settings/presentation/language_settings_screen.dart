import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../application/locale_controller.dart';

const _englishKeywords = ['english'];
const _tamilKeywords = ['tamil', 'தமிழ்'];
const _autoKeywords = ['auto', 'automatic', 'தானாக'];

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen>
    with HandsFreeLoopMixin<LanguageSettingsScreen> {
  bool _announced = false;

  String _currentLabel(AppLocalizations l10n, String current) => switch (current) {
        'en' => l10n.languageEnglish,
        'ta' => l10n.languageTamil,
        _ => l10n.languageAuto,
      };

  Future<void> _announce(AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final current = ref.read(localeControllerProvider);
    final text = '${l10n.languageSettingsTitle}: ${_currentLabel(l10n, current)}.';
    await ref.read(ttsServiceProvider).speak(text, language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final lower = text.trim().toLowerCase();
    final controller = ref.read(localeControllerProvider.notifier);

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (_tamilKeywords.any(lower.contains)) {
      await controller.setLanguage('ta');
    } else if (_englishKeywords.any(lower.contains)) {
      await controller.setLanguage('en');
    } else if (_autoKeywords.any(lower.contains)) {
      await controller.setLanguage('auto');
    } else if (VoiceCommandParser.parse(text) == VoiceCommand.repeatLast) {
      await ref.read(ttsServiceProvider).repeatLast();
    }

    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(l10n));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      body: SafeArea(
        child: RadioGroup<String>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) controller.setLanguage(value);
          },
          child: ListView(
            children: [
              RadioListTile<String>(title: Text(l10n.languageAuto), value: 'auto'),
              RadioListTile<String>(title: Text(l10n.languageEnglish), value: 'en'),
              RadioListTile<String>(title: Text(l10n.languageTamil), value: 'ta'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleListening(onFinalResult: _handleVoiceCommand),
        tooltip: isListening ? l10n.micListeningLabel : l10n.micIdleLabel,
        backgroundColor: isListening ? Theme.of(context).colorScheme.error : null,
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
