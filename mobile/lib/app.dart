import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/accessibility/active_voice_screen.dart';
import 'core/localization/generated/app_localizations.dart';
import 'core/providers/core_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/locale_controller.dart';

class NalamAiApp extends ConsumerWidget {
  const NalamAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider.select((_) => ref.read(localeControllerProvider.notifier).effectiveLocale));

    return MaterialApp.router(
      title: 'NalamAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Never let a system font-scale setting shrink text below the app's own accessible
        // baseline — a low-vision user's larger system setting should always be honoured, but
        // an unusual smaller-than-default system setting should not undercut our minimums.
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 3.0);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: _VoiceGestureShell(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// An app-wide "talk to me" surface.
///
/// Finding a button is a visual act. Even a deliberately huge microphone button assumes the
/// user knows roughly where it is, and after navigating between screens they often do not. So
/// the whole window answers two gestures, on every screen, with no target to locate:
///
///  * **double tap** — reopen the microphone for whatever screen is in front (see
///    [ActiveVoiceScreen]);
///  * **press and hold** — repeat the last thing the app said, for a sentence lost to a bus
///    going past.
///
/// This is a supplement, not the mechanism. It sits above the routes with translucent hit
/// testing, so single taps still reach the buttons underneath, and a screen reader such as
/// TalkBack or VoiceOver claims these gestures for itself when it is running. The app therefore
/// never depends on them: screens speak and open the microphone on their own (see
/// HandsFreeLoopMixin), and every action also has a labelled control.
class _VoiceGestureShell extends ConsumerWidget {
  const _VoiceGestureShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onDoubleTap: () async {
        await ref.read(hapticServiceProvider).tap();
        if (ref.read(activeVoiceScreenProvider).requestListen()) return;
        // Nothing is listening yet (the app is still starting up) — say so rather than
        // leaving the tap unanswered.
        if (!context.mounted) return;
        await ref.read(ttsServiceProvider).speak(
              AppLocalizations.of(context).bootSpoken,
              language: ref.read(localeControllerProvider) == 'ta' ? 'ta' : 'en',
            );
      },
      onLongPress: () async {
        await ref.read(hapticServiceProvider).tap();
        await ref.read(ttsServiceProvider).repeatLast();
      },
      child: child,
    );
  }
}
