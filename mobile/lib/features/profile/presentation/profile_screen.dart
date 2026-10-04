import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/profile.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_provider.dart';

String _preferenceLabel(AppLocalizations l10n, DietaryPreference pref) => switch (pref) {
      DietaryPreference.none => l10n.dietPrefNone,
      DietaryPreference.vegetarian => l10n.dietPrefVegetarian,
      DietaryPreference.vegan => l10n.dietPrefVegan,
      DietaryPreference.eggetarian => l10n.dietPrefEggetarian,
      DietaryPreference.nonVegetarian => l10n.dietPrefNonVegetarian,
    };

const _preferencesKeywords = ['preferences', 'allergies', 'diet', 'ஒவ்வாமை', 'உணவு விருப்பம்'];
const _logoutKeywords = ['log out', 'logout', 'sign out', 'வெளியேறு'];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with HandsFreeLoopMixin<ProfileScreen> {
  bool _announced = false;

  Future<void> _announce(UserProfile? profile, AppLocalizations l10n) async {
    if (_announced || profile == null) return;
    _announced = true;

    final buffer = StringBuffer('${l10n.dietaryPreferenceLabel}: ${_preferenceLabel(l10n, profile.dietaryPreference)}. ');
    buffer.write('${l10n.allergiesTitle}: ');
    buffer.write(profile.allergies.isEmpty ? l10n.noAllergiesYet : profile.allergies.map((a) => a.allergen).join(', '));
    buffer.write('. ${l10n.restrictionsTitle}: ');
    buffer.write(
      profile.restrictions.isEmpty ? l10n.noRestrictionsYet : profile.restrictions.map((r) => r.restriction).join(', '),
    );

    await ref.read(ttsServiceProvider).speak(buffer.toString(), language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final lower = text.trim().toLowerCase();

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (_preferencesKeywords.any(lower.contains)) {
      context.push(AppRoutes.preferences);
      return;
    }
    if (_logoutKeywords.any(lower.contains)) {
      await ref.read(authControllerProvider.notifier).logout();
      return;
    }
    if (VoiceCommandParser.parse(text) == VoiceCommand.repeatLast) {
      await ref.read(ttsServiceProvider).repeatLast();
    }

    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (authState.user != null) ...[
                    Text(l10n.accountSection, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(authState.user!.email),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  profileAsync.when(
                    data: (profile) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _announce(profile, l10n));
                      return _ProfileSummary(profile: profile, l10n: l10n);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Text(l10n.errorGeneric),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.preferences),
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.allergiesTitle),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logoutButton),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
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

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile, required this.l10n});
  final UserProfile? profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (profile == null) return Text(l10n.errorGeneric);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dietaryPreferenceLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(_preferenceLabel(l10n, profile!.dietaryPreference), style: theme.textTheme.bodyLarge),
            const Divider(height: 24),
            Text(l10n.allergiesTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              profile!.allergies.isEmpty
                  ? l10n.noAllergiesYet
                  : profile!.allergies.map((a) => a.allergen).join(', '),
              style: theme.textTheme.bodyLarge,
            ),
            const Divider(height: 24),
            Text(l10n.restrictionsTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              profile!.restrictions.isEmpty
                  ? l10n.noRestrictionsYet
                  : profile!.restrictions.map((r) => r.restriction).join(', '),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
