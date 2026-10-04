import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/voice_input_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/big_mic_button.dart';
import '../../settings/application/locale_controller.dart';
import '../application/auth_controller.dart';

/// The first thing a new user meets, and the one screen that used to make the app unusable for
/// the person it was built for: it asked a blind user to type an email address and a password.
///
/// It now asks for one spoken word. [AuthController.signInHandsFree] mints and registers this
/// device's account behind the scenes (see DeviceAccountStore), so there is no address to
/// dictate, no password to remember, and nothing to spell out loud in a shop. The typed form
/// still exists one tap away for a sighted helper setting up someone's phone, because
/// voice-first must not mean voice-only.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Anything a person might plausibly answer "shall I set this up?" with. This is deliberately
  // permissive: a false positive costs a spoken confirmation, a false negative strands someone
  // who cannot see the button they are supposed to press instead.
  static const _goKeywords = [
    'start', 'begin', 'set up', 'setup', 'create', 'yes', 'yeah', 'okay', 'ok', 'sure',
    'continue', 'go ahead', 'sign in', 'sign me in', 'log in', 'login', 'try again', 'retry',
    'தொடங்கு', 'தொடங்கவும்', 'சரி', 'ஆம்', 'உள்நுழை', 'மீண்டும்',
  ];
  static const _helpKeywords = ['help', 'what do i say', 'what can i say', 'உதவி'];

  bool _busy = false;
  bool _started = false;
  bool _listening = false;
  bool _showTypedForm = false;
  bool _micUsable = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String get _language {
    final setting = ref.read(localeControllerProvider);
    return setting == 'ta' ? 'ta' : 'en';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _greetAndListen());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// A returning user who signed out gets "say sign in"; a brand-new user gets the full
  /// explanation of what is about to be created for them. Consent is spoken, not assumed —
  /// the account is only minted once they answer.
  Future<void> _greetAndListen() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final hasAccount = await ref.read(deviceAccountStoreProvider).exists();
    if (!mounted) return;

    await _speak(hasAccount ? l10n.voiceSignInPrompt : l10n.voiceSetupPrompt);
    await _listen();
  }

  Future<void> _speak(String text) =>
      ref.read(ttsServiceProvider).speak(text, language: _language);

  Future<void> _listen() async {
    if (!mounted || _busy) return;
    final voiceInput = ref.read(voiceInputServiceProvider);
    await ref.read(hapticServiceProvider).tap();

    final status = await voiceInput.listen(
      language: ref.read(localeControllerProvider),
      onResult: (text, isFinal) {
        if (isFinal && text.trim().isNotEmpty) _handleSpeech(text);
      },
    );

    if (!mounted) return;
    if (status == VoiceInputStatus.listening) {
      setState(() => _listening = true);
      return;
    }

    // No microphone means no way in by voice, so make the fallback impossible to miss: say what
    // happened, buzz, and leave one full-width button that does the whole setup on a single tap.
    setState(() {
      _listening = false;
      _micUsable = false;
    });
    final l10n = AppLocalizations.of(context);
    await ref.read(hapticServiceProvider).warning();
    await _speak(status == VoiceInputStatus.permissionDenied
        ? l10n.permissionMicDenied
        : l10n.micUnavailableSpoken);
  }

  Future<void> _handleSpeech(String rawText) async {
    if (!mounted) return;
    setState(() => _listening = false);
    final text = rawText.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);

    if (_helpKeywords.any(text.contains)) {
      await _speak(l10n.voiceSetupRetryHint);
      await _listen();
      return;
    }
    if (_goKeywords.any(text.contains)) {
      await _runHandsFreeSetup();
      return;
    }

    await _speak(l10n.voiceSetupRetryHint);
    await _listen();
  }

  /// Creates-or-signs-into this device's account. On success the router's redirect takes over
  /// and lands the user on Home, so there is no navigation to do here.
  Future<void> _runHandsFreeSetup() async {
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = AppLocalizations.of(context);
    final hadAccount = await ref.read(deviceAccountStoreProvider).exists();
    if (!mounted) return;
    await _speak(hadAccount ? l10n.voiceSignInWorking : l10n.voiceSetupWorking);

    final ok = await ref.read(authControllerProvider.notifier).signInHandsFree();
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      await ref.read(hapticServiceProvider).infoNotice();
      await _speak(l10n.voiceSetupDone);
      return;
    }

    final failure = ref.read(authControllerProvider).lastError;
    await ref.read(hapticServiceProvider).warning();
    await _speak('${l10n.voiceSetupFailed} ${failure?.message ?? ''}'.trim());
    if (_micUsable) await _listen();
  }

  Future<void> _submitTypedForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final l10n = AppLocalizations.of(context);
      final error = ref.read(authControllerProvider).lastError;
      final message = error?.message ?? l10n.errorGeneric;
      await _speak(message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              // liveRegion so a screen-reader user hears the same prompt and the same progress
              // updates that the speaker is giving everyone else.
              Semantics(
                liveRegion: true,
                child: Text(
                  _busy ? l10n.voiceSetupWorking : l10n.voiceSetupPrompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 32),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else ...[
                Center(
                  child: BigMicButton(
                    isListening: _listening,
                    onPressed: _listening ? _stopListening : _listen,
                    idleLabel: l10n.micIdleLabel,
                    listeningLabel: l10n.micListeningLabel,
                  ),
                ),
                const SizedBox(height: 24),
                // The one-tap escape hatch: works with no microphone, and is the whole setup
                // for a helper configuring the phone for someone.
                FilledButton.icon(
                  onPressed: _runHandsFreeSetup,
                  icon: const Icon(Icons.record_voice_over),
                  label: Text(l10n.voiceSetupButton),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                ),
              ],
              const SizedBox(height: 32),
              // Collapsed by default: the typed path is for sighted helpers and existing
              // email accounts, and putting it front and centre is what broke this screen.
              ExpansionTile(
                title: Text(l10n.voiceSetupTypeInstead, style: theme.textTheme.bodyMedium),
                initiallyExpanded: _showTypedForm,
                onExpansionChanged: (value) => setState(() => _showTypedForm = value),
                children: [_buildTypedForm(context, l10n)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _stopListening() async {
    await ref.read(voiceInputServiceProvider).stop();
    if (mounted) setState(() => _listening = false);
  }

  Widget _buildTypedForm(BuildContext context, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.emailLabel),
            validator: (value) => (value == null || !value.contains('@')) ? l10n.emailLabel : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l10n.passwordLabel),
            validator: (value) => (value == null || value.length < 8) ? l10n.passwordLabel : null,
            onFieldSubmitted: (_) => _submitTypedForm(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submitTypedForm,
            child: Text(l10n.loginButton),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.register),
            child: Text(l10n.switchToRegister),
          ),
        ],
      ),
    );
  }
}
