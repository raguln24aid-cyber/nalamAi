import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../application/settings_controller.dart';

const _languageKeywords = ['language', 'மொழி'];
const _hapticsKeywords = ['haptic', 'vibration', 'அதிர்வு'];
const _cloudVoiceKeywords = ['cloud voice', 'cloud tts', 'உயர்தர'];
const _onKeywords = ['on', 'enable', 'இயக்கு'];
const _offKeywords = ['off', 'disable', 'நிறுத்து'];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with HandsFreeLoopMixin<SettingsScreen> {
  bool _announced = false;

  static String _onOffLabel(bool value) => value ? 'on' : 'off';

  Future<void> _announce(AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final settings = ref.read(settingsControllerProvider);
    final text = '${l10n.settingsTitle}. '
        '${l10n.hapticFeedbackToggle}: ${_onOffLabel(settings.hapticsEnabled)}. '
        '${l10n.cloudVoiceFallbackToggle}: ${_onOffLabel(settings.cloudTtsFallbackEnabled)}.';
    await ref.read(ttsServiceProvider).speak(text, language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final lower = text.trim().toLowerCase();
    final controller = ref.read(settingsControllerProvider.notifier);

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (_languageKeywords.any(lower.contains)) {
      context.push(AppRoutes.languageSettings);
      return;
    }

    final wantsOn = _onKeywords.any(lower.contains);
    final wantsOff = _offKeywords.any(lower.contains);
    if (_hapticsKeywords.any(lower.contains) && (wantsOn || wantsOff)) {
      await controller.setHapticsEnabled(wantsOn);
    } else if (_cloudVoiceKeywords.any(lower.contains) && (wantsOn || wantsOff)) {
      await controller.setCloudTtsFallbackEnabled(wantsOn);
    } else if (VoiceCommandParser.parse(text) == VoiceCommand.repeatLast) {
      await ref.read(ttsServiceProvider).repeatLast();
    }

    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(l10n));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text(l10n.languageSettingsTitle),
              leading: const Icon(Icons.language),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.languageSettings),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l10n.voiceSettingsSection, style: Theme.of(context).textTheme.labelLarge),
            ),
            SwitchListTile(
              title: Text(l10n.hapticFeedbackToggle),
              value: settings.hapticsEnabled,
              onChanged: controller.setHapticsEnabled,
            ),
            SwitchListTile(
              title: Text(l10n.cloudVoiceFallbackToggle),
              value: settings.cloudTtsFallbackEnabled,
              onChanged: controller.setCloudTtsFallbackEnabled,
            ),
          ],
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
