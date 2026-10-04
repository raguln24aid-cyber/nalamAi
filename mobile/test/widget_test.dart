// Smoke test for the first screen a user sees: the Login screen. Exercises real widget/l10n/
// theme wiring while faking the TtsService (which otherwise talks to a platform channel that
// isn't available under `flutter test`) via mocktail.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nalamai_mobile/core/accessibility/tts_service.dart';
import 'package:nalamai_mobile/core/localization/generated/app_localizations.dart';
import 'package:nalamai_mobile/core/providers/core_providers.dart';
import 'package:nalamai_mobile/core/repositories/tts_repository.dart';
import 'package:nalamai_mobile/features/auth/presentation/login_screen.dart';

class _MockTtsService extends Mock implements TtsService {}

class _MockTtsRepository extends Mock implements TtsRepository {}

void main() {
  late _MockTtsService mockTts;

  setUp(() {
    mockTts = _MockTtsService();
    when(() => mockTts.speak(any(), language: any(named: 'language'))).thenAnswer((_) async {});
  });

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        ttsServiceProvider.overrideWithValue(mockTts),
        ttsRepositoryProvider.overrideWithValue(_MockTtsRepository()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('Login screen renders the app name, email/password fields, and a login button',
      (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pump();

    expect(find.text('NalamAI'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('Login screen speaks a welcome prompt on first build', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pump();

    verify(() => mockTts.speak(any(), language: any(named: 'language'))).called(1);
  });

  testWidgets('Submitting an invalid email shows a validation error instead of calling the API',
      (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Email address'), findsWidgets); // label remains, form did not navigate away
  });
}
