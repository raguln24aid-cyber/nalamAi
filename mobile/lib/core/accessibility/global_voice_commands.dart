import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/settings/application/locale_controller.dart';
import '../localization/generated/app_localizations.dart';
import '../providers/core_providers.dart';
import '../routing/app_router.dart';
import 'language_hint.dart';

/// Commands that mean the same thing on every screen.
///
/// A sighted user recovers from a wrong turn by glancing at the screen and tapping the right
/// thing. A blind user cannot, so "go home", "go back", "help" and "where am I" have to work
/// from wherever they are — including from screens whose own vocabulary is entirely different.
/// Screens consult [GlobalVoiceCommands.parse] before their own parser, so these always win.
enum GlobalVoiceCommand {
  home,
  back,
  scan,
  history,
  profile,
  settings,
  help,
  repeat,
  whereAmI,
  stopTalking,
  signOut,
  unknown,
}

class GlobalVoiceCommands {
  GlobalVoiceCommands._();

  // Ordered most-specific first: "go back home" must not match plain "back".
  static const _home = ['go home', 'home screen', 'main menu', 'go to home', 'முகப்பு'];
  static const _back = ['go back', 'previous screen', 'back', 'பின் செல்', 'திரும்பு', 'பின்னால்'];
  static const _scan = [
    'scan a product', 'scan product', 'check this product', 'scan this', 'check product',
    'new scan', 'scan', 'ஸ்கேன்', 'ஸ்கேன் செய்', 'பொருளை பார்',
  ];
  static const _history = ['my history', 'scan history', 'history', 'past scans', 'previous scans', 'வரலாறு'];
  static const _profile = ['my profile', 'profile', 'my allergies', 'சுயவிவரம்'];
  static const _settings = ['settings', 'அமைப்பு', 'அமைப்புகள்'];
  static const _help = [
    'help', 'what can i say', 'what can i do', 'commands', 'options',
    'உதவி', 'என்ன சொல்லலாம்',
  ];
  static const _repeat = ['repeat that', 'repeat', 'say again', 'say that again', 'மீண்டும் சொல்', 'திரும்ப சொல்'];
  static const _whereAmI = ['where am i', 'what screen', 'which screen', 'நான் எங்கே', 'எந்த திரை'];
  static const _stop = ['stop talking', 'be quiet', 'stop', 'silence', 'quiet', 'நிறுத்து', 'அமைதி'];
  static const _signOut = ['sign out', 'log out', 'logout', 'வெளியேறு'];

  static GlobalVoiceCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return GlobalVoiceCommand.unknown;

    if (_matches(text, _whereAmI)) return GlobalVoiceCommand.whereAmI;
    if (_matches(text, _help)) return GlobalVoiceCommand.help;
    if (_matches(text, _signOut)) return GlobalVoiceCommand.signOut;
    if (_matches(text, _repeat)) return GlobalVoiceCommand.repeat;
    if (_matches(text, _stop)) return GlobalVoiceCommand.stopTalking;
    if (_matches(text, _home)) return GlobalVoiceCommand.home;
    if (_matches(text, _back)) return GlobalVoiceCommand.back;
    if (_matches(text, _history)) return GlobalVoiceCommand.history;
    if (_matches(text, _profile)) return GlobalVoiceCommand.profile;
    if (_matches(text, _settings)) return GlobalVoiceCommand.settings;
    if (_matches(text, _scan)) return GlobalVoiceCommand.scan;

    return GlobalVoiceCommand.unknown;
  }

  /// Multi-word keywords ("go back", "scan a product") are unambiguous enough to match anywhere
  /// in the utterance. Bare single words are not: on the assistant screen someone can perfectly
  /// reasonably ask "is this good for my back?" or "how much sugar should I stop at?", and a
  /// naive substring match would answer by navigating away mid-question. A lone word therefore
  /// only counts when the utterance essentially *is* that command — an exact match, or a word
  /// hit in a phrase short enough to be a command rather than a question.
  static bool _matches(String text, List<String> keywords) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    for (final keyword in keywords) {
      if (keyword.contains(' ')) {
        if (text.contains(keyword)) return true;
        continue;
      }
      if (text == keyword) return true;
      if (wordCount <= 3 && _containsWord(text, keyword)) return true;
    }
    return false;
  }

  static bool _containsWord(String text, String word) =>
      RegExp('(^|\\s)${RegExp.escape(word)}(\$|\\s|[.,!?])').hasMatch(text);
}

/// Runs a [GlobalVoiceCommand] against the router and the speech layer.
class GlobalVoiceRouter {
  const GlobalVoiceRouter(this._ref, this._context);

  final WidgetRef _ref;
  final BuildContext _context;

  /// Handles [text] if it is a global command, returning true when it did — so a screen's own
  /// parser only ever sees speech that is not one of these.
  ///
  /// [navigated] fires for commands that leave the screen, so the caller can stop its own
  /// listen loop rather than re-arm a microphone on a screen that is going away.
  Future<bool> handle(String text, {VoidCallback? navigated}) async {
    final command = GlobalVoiceCommands.parse(text);
    if (command == GlobalVoiceCommand.unknown) return false;

    final tts = _ref.read(ttsServiceProvider);
    final l10n = AppLocalizations.of(_context);
    final language = _spokenLanguage(text);

    switch (command) {
      case GlobalVoiceCommand.stopTalking:
        await tts.stop();
      case GlobalVoiceCommand.repeat:
        await tts.repeatLast();
      case GlobalVoiceCommand.help:
        await tts.speak(helpText(l10n), language: language);
      case GlobalVoiceCommand.whereAmI:
        await tts.speak(l10n.whereAmIAnswer(currentScreenName(l10n)), language: language);
      case GlobalVoiceCommand.home:
        navigated?.call();
        if (_context.mounted) _context.go(AppRoutes.home);
      case GlobalVoiceCommand.back:
        navigated?.call();
        if (!_context.mounted) return true;
        if (_context.canPop()) {
          _context.pop();
        } else {
          _context.go(AppRoutes.home);
        }
      case GlobalVoiceCommand.scan:
        navigated?.call();
        if (_context.mounted) _context.push(AppRoutes.scanner);
      case GlobalVoiceCommand.history:
        navigated?.call();
        if (_context.mounted) _context.push(AppRoutes.history);
      case GlobalVoiceCommand.profile:
        navigated?.call();
        if (_context.mounted) _context.push(AppRoutes.profile);
      case GlobalVoiceCommand.settings:
        navigated?.call();
        if (_context.mounted) _context.push(AppRoutes.settings);
      case GlobalVoiceCommand.signOut:
        navigated?.call();
        await tts.speak(l10n.signedOutSpoken, language: language);
        await _ref.read(authControllerProvider.notifier).logout();
      case GlobalVoiceCommand.unknown:
        return false;
    }
    return true;
  }

  String _spokenLanguage(String heardText) {
    final setting = _ref.read(localeControllerProvider);
    return setting == 'auto' ? LanguageHint.detect(heardText) : setting;
  }

  /// The commands available everywhere, prefixed by the ones specific to where the user is.
  String helpText(AppLocalizations l10n) {
    final location = _location();
    final screenSpecific = switch (location) {
      final String l when l.endsWith('/assistant') => l10n.helpAssistant,
      final String l when l.startsWith('/result') => l10n.helpProductResult,
      AppRoutes.scanner => l10n.helpScanner,
      AppRoutes.history => l10n.helpHistory,
      AppRoutes.profile || AppRoutes.preferences => l10n.helpProfile,
      AppRoutes.settings || AppRoutes.languageSettings => l10n.helpSettings,
      AppRoutes.home => l10n.helpHome,
      _ => '',
    };
    return screenSpecific.isEmpty ? l10n.helpGlobal : '$screenSpecific ${l10n.helpGlobal}';
  }

  String currentScreenName(AppLocalizations l10n) {
    final location = _location();
    return switch (location) {
      final String l when l.endsWith('/assistant') => l10n.assistantTitle,
      final String l when l.endsWith('/nutrition') => l10n.nutritionTitle,
      final String l when l.endsWith('/ingredients') => l10n.ingredientsTitle,
      final String l when l.startsWith('/result') => l10n.productResultTitle,
      AppRoutes.scanner => l10n.scannerTitle,
      AppRoutes.history => l10n.historyTitle,
      AppRoutes.profile => l10n.profileTitle,
      AppRoutes.preferences => l10n.allergiesTitle,
      AppRoutes.settings => l10n.settingsTitle,
      AppRoutes.languageSettings => l10n.languageSettingsTitle,
      AppRoutes.comparison => l10n.comparisonTitle,
      AppRoutes.login || AppRoutes.register => l10n.authLoginTitle,
      _ => l10n.homeTitle,
    };
  }

  String _location() => GoRouterState.of(_context).matchedLocation;
}
