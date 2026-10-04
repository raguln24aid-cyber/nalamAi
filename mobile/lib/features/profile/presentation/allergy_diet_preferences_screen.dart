import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/profile.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../application/profile_provider.dart';

String _preferenceLabel(AppLocalizations l10n, DietaryPreference pref) => switch (pref) {
      DietaryPreference.none => l10n.dietPrefNone,
      DietaryPreference.vegetarian => l10n.dietPrefVegetarian,
      DietaryPreference.vegan => l10n.dietPrefVegan,
      DietaryPreference.eggetarian => l10n.dietPrefEggetarian,
      DietaryPreference.nonVegetarian => l10n.dietPrefNonVegetarian,
    };

/// Extracts the free-form part of a voice command after any of [triggers] first appears — e.g.
/// "allergic to peanuts" with trigger "allergic to " -> "peanuts". Simple substring-based
/// extraction, same keyword-driven philosophy as the rest of core/accessibility.
String? _extractAfter(String text, List<String> triggers) {
  final lower = text.toLowerCase();
  for (final trigger in triggers) {
    final idx = lower.indexOf(trigger);
    if (idx != -1) {
      final after = text.substring(idx + trigger.length).trim();
      if (after.isNotEmpty) return after;
    }
  }
  return null;
}

class AllergyDietPreferencesScreen extends ConsumerStatefulWidget {
  const AllergyDietPreferencesScreen({super.key});

  @override
  ConsumerState<AllergyDietPreferencesScreen> createState() => _AllergyDietPreferencesScreenState();
}

class _AllergyDietPreferencesScreenState extends ConsumerState<AllergyDietPreferencesScreen>
    with HandsFreeLoopMixin<AllergyDietPreferencesScreen> {
  bool _announced = false;

  Future<void> _announce(UserProfile profile, AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final buffer = StringBuffer(
      '${l10n.dietaryPreferenceLabel}: ${_preferenceLabel(l10n, profile.dietaryPreference)}. ',
    );
    buffer.write('${l10n.allergiesTitle}: ');
    buffer.write(profile.allergies.isEmpty ? l10n.noAllergiesYet : profile.allergies.map((a) => a.allergen).join(', '));
    buffer.write('.');
    await ref.read(ttsServiceProvider).speak(buffer.toString(), language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final l10n = AppLocalizations.of(context);
    final tts = ref.read(ttsServiceProvider);
    final repo = ref.read(profileRepositoryProvider);
    final lower = text.trim().toLowerCase();

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (VoiceCommandParser.parse(text) == VoiceCommand.repeatLast) {
      await tts.repeatLast();
      if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
      return;
    }

    final profile = ref.read(userProfileProvider).value;

    // Dietary preference — check the more specific phrases before the bare "vegetarian" match,
    // since "non-vegetarian" and "eggetarian" both contain "vegetarian"/"egg" as a substring.
    DietaryPreference? newPreference;
    if (lower.contains('non vegetarian') || lower.contains('non-vegetarian') || lower.contains('nonveg')) {
      newPreference = DietaryPreference.nonVegetarian;
    } else if (lower.contains('vegan')) {
      newPreference = DietaryPreference.vegan;
    } else if (lower.contains('eggetarian')) {
      newPreference = DietaryPreference.eggetarian;
    } else if (lower.contains('vegetarian')) {
      newPreference = DietaryPreference.vegetarian;
    } else if (lower.contains('no preference') || lower == 'none') {
      newPreference = DietaryPreference.none;
    }
    if (newPreference != null) {
      await repo.updateDietaryPreference(newPreference);
      ref.invalidate(userProfileProvider);
      await tts.speak(
        '${l10n.dietaryPreferenceLabel}: ${_preferenceLabel(l10n, newPreference)}.',
        language: spokenLanguage,
      );
      if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
      return;
    }

    final wantsRemove = lower.contains('remove') || lower.contains('delete');

    if (wantsRemove && lower.contains('allerg') && profile != null) {
      final name = _extractAfter(text, ['allergy ', 'allergies ', 'allergic to ']);
      final match = profile.allergies.where(
        (a) => name != null && (a.allergen.toLowerCase().contains(name.toLowerCase()) || lower.contains(a.allergen.toLowerCase())),
      );
      if (match.isNotEmpty) {
        await repo.removeAllergy(match.first.id);
        ref.invalidate(userProfileProvider);
        await tts.speak(l10n.done, language: spokenLanguage);
      } else {
        await tts.speak(l10n.errorGeneric, language: spokenLanguage);
      }
    } else if (wantsRemove && lower.contains('restrict') && profile != null) {
      final name = _extractAfter(text, ['restriction ', 'restrictions ']);
      final match = profile.restrictions.where(
        (r) => name != null && (r.restriction.toLowerCase().contains(name.toLowerCase()) || lower.contains(r.restriction.toLowerCase())),
      );
      if (match.isNotEmpty) {
        await repo.removeRestriction(match.first.id);
        ref.invalidate(userProfileProvider);
        await tts.speak(l10n.done, language: spokenLanguage);
      } else {
        await tts.speak(l10n.errorGeneric, language: spokenLanguage);
      }
    } else if (lower.contains('allerg')) {
      final name = _extractAfter(text, ['allergic to ', 'allergy to ', 'allergies to ', 'add allergy ', 'allergy ']);
      if (name != null && name.isNotEmpty) {
        final severity = lower.contains('severe')
            ? AllergySeverity.severe
            : lower.contains('mild')
                ? AllergySeverity.mild
                : AllergySeverity.moderate;
        await repo.addAllergy(allergen: name, severity: severity);
        ref.invalidate(userProfileProvider);
        await tts.speak('${l10n.addAllergyButton}: $name.', language: spokenLanguage);
      } else {
        await tts.speak(l10n.addAllergyButton, language: spokenLanguage);
      }
    } else if (lower.contains('restrict')) {
      final name = _extractAfter(text, ['add restriction ', 'restriction ']);
      if (name != null && name.isNotEmpty) {
        await repo.addRestriction(name);
        ref.invalidate(userProfileProvider);
        await tts.speak('${l10n.addRestrictionButton}: $name.', language: spokenLanguage);
      } else {
        await tts.speak(l10n.addRestrictionButton, language: spokenLanguage);
      }
    } else {
      await tts.speak(l10n.allergiesTitle, language: spokenLanguage);
    }

    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.allergiesTitle)),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) return Center(child: Text(l10n.errorGeneric));
            WidgetsBinding.instance.addPostFrameCallback((_) => _announce(profile, l10n));
            return _EditableProfile(profile: profile);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
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

class _EditableProfile extends ConsumerWidget {
  const _EditableProfile({required this.profile});
  final UserProfile profile;

  Future<void> _setPreference(WidgetRef ref, DietaryPreference? value) async {
    if (value == null) return;
    await ref.read(profileRepositoryProvider).updateDietaryPreference(value);
    ref.invalidate(userProfileProvider);
  }

  Future<void> _addAllergy(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<(String, AllergySeverity)>(
      context: context,
      builder: (context) => _AddAllergyDialog(l10n: l10n),
    );
    if (result == null) return;
    await ref.read(profileRepositoryProvider).addAllergy(allergen: result.$1, severity: result.$2);
    ref.invalidate(userProfileProvider);
  }

  Future<void> _addRestriction(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addRestrictionButton),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    await ref.read(profileRepositoryProvider).addRestriction(value);
    ref.invalidate(userProfileProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.dietaryPreferenceLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<DietaryPreference>(
          initialValue: profile.dietaryPreference,
          items: [
            DropdownMenuItem(value: DietaryPreference.none, child: Text(l10n.dietPrefNone)),
            DropdownMenuItem(value: DietaryPreference.vegetarian, child: Text(l10n.dietPrefVegetarian)),
            DropdownMenuItem(value: DietaryPreference.vegan, child: Text(l10n.dietPrefVegan)),
            DropdownMenuItem(value: DietaryPreference.eggetarian, child: Text(l10n.dietPrefEggetarian)),
            DropdownMenuItem(value: DietaryPreference.nonVegetarian, child: Text(l10n.dietPrefNonVegetarian)),
          ],
          onChanged: (value) => _setPreference(ref, value),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Text(l10n.allergiesTitle, style: theme.textTheme.titleMedium)),
            IconButton(
              onPressed: () => _addAllergy(context, ref),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.addAllergyButton,
            ),
          ],
        ),
        if (profile.allergies.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noAllergiesYet))
        else
          ...profile.allergies.map(
            (allergy) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(allergy.allergen),
              subtitle: Text(allergy.severity.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).removeAllergy(allergy.id);
                  ref.invalidate(userProfileProvider);
                },
              ),
            ),
          ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Text(l10n.restrictionsTitle, style: theme.textTheme.titleMedium)),
            IconButton(
              onPressed: () => _addRestriction(context, ref),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.addRestrictionButton,
            ),
          ],
        ),
        if (profile.restrictions.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noRestrictionsYet))
        else
          ...profile.restrictions.map(
            (restriction) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(restriction.restriction),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).removeRestriction(restriction.id);
                  ref.invalidate(userProfileProvider);
                },
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _AddAllergyDialog extends StatefulWidget {
  const _AddAllergyDialog({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_AddAllergyDialog> createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends State<_AddAllergyDialog> {
  final _controller = TextEditingController();
  AllergySeverity _severity = AllergySeverity.moderate;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.addAllergyButton),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _controller, autofocus: true),
          const SizedBox(height: 16),
          SegmentedButton<AllergySeverity>(
            segments: [
              ButtonSegment(value: AllergySeverity.mild, label: Text(l10n.allergySeverityMild)),
              ButtonSegment(value: AllergySeverity.moderate, label: Text(l10n.allergySeverityModerate)),
              ButtonSegment(value: AllergySeverity.severe, label: Text(l10n.allergySeveritySevere)),
            ],
            selected: {_severity},
            onSelectionChanged: (selection) => setState(() => _severity = selection.first),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, (text, _severity));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
