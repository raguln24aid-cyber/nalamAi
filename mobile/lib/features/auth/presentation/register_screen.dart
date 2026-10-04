import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _preferredLanguage = 'auto';
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          preferredLanguage: _preferredLanguage,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      final error = ref.read(authControllerProvider).lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegisterTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                    validator: (value) =>
                        (value == null || !value.contains('@')) ? l10n.emailLabel : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(labelText: l10n.passwordLabel),
                    validator: (value) =>
                        (value == null || value.length < 8) ? l10n.passwordLabel : null,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: l10n.languageSettingsTitle,
                    child: DropdownButtonFormField<String>(
                      initialValue: _preferredLanguage,
                      decoration: InputDecoration(labelText: l10n.languageSettingsTitle),
                      items: [
                        DropdownMenuItem(value: 'auto', child: Text(l10n.languageAuto)),
                        DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                        DropdownMenuItem(value: 'ta', child: Text(l10n.languageTamil)),
                      ],
                      onChanged: (value) => setState(() => _preferredLanguage = value ?? 'auto'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.registerButton),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.pop(), child: Text(l10n.switchToLogin)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
