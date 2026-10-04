import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/label_speech.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/product.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/provenance_label.dart';
import '../application/scan_detail_provider.dart';

class IngredientsAllergensScreen extends ConsumerStatefulWidget {
  const IngredientsAllergensScreen({super.key, required this.scanId});
  final String scanId;

  @override
  ConsumerState<IngredientsAllergensScreen> createState() => _IngredientsAllergensScreenState();
}

class _IngredientsAllergensScreenState extends ConsumerState<IngredientsAllergensScreen>
    with HandsFreeLoopMixin<IngredientsAllergensScreen> {
  bool _announced = false;

  Future<void> _announce(Scan scan, AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final product = scan.product;
    final segments = [
      LabelSpeech.ingredients(product?.ingredients ?? const [], l10n) ?? l10n.noIngredientsFound,
      LabelSpeech.allergens(product?.allergens ?? const [], l10n) ?? l10n.noAllergensFound,
      if (LabelSpeech.dietFlags(product?.dietFlags ?? const [], l10n) != null)
        LabelSpeech.dietFlags(product!.dietFlags, l10n)!,
    ];

    final tts = ref.read(ttsServiceProvider);
    for (final segment in segments) {
      if (!mounted) return;
      await tts.speak(segment, language: spokenLanguage);
    }

    if (mounted && autoListenActive) {
      await startListening(onFinalResult: _handleVoiceCommand);
    }
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final tts = ref.read(ttsServiceProvider);

    if (CommonVoiceCommands.isBack(text)) {
      if (context.canPop()) context.pop();
      return;
    }
    if (CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }

    final command = ProductResultVoiceParser.parse(text);
    switch (command) {
      case ProductResultCommand.viewNutrition:
        context.push(AppRoutes.nutritionPath(widget.scanId));
        return;
      case ProductResultCommand.rescan:
        context.pushReplacement(AppRoutes.scanner);
        return;
      case ProductResultCommand.askQuestion:
        context.push(AppRoutes.assistantPath(widget.scanId), extra: text);
        return;
      case ProductResultCommand.repeatLast:
        await tts.repeatLast();
      case ProductResultCommand.viewIngredients:
      case ProductResultCommand.compare:
      case ProductResultCommand.unknown:
        final l10n = AppLocalizations.of(context);
        await tts.speak(l10n.assistantHint, language: spokenLanguage);
    }

    if (mounted && autoListenActive) {
      await startListening(onFinalResult: _handleVoiceCommand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanAsync = ref.watch(scanDetailProvider(widget.scanId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingredientsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: scanAsync.when(
                data: (scan) {
                  if (scan?.product == null) return Center(child: Text(l10n.errorGeneric));
                  WidgetsBinding.instance.addPostFrameCallback((_) => _announce(scan!, l10n));
                  return _buildContent(context, l10n, scan!);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.errorGeneric)),
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

  Widget _buildContent(BuildContext context, AppLocalizations l10n, Scan scan) {
    final theme = Theme.of(context);
    final product = scan.product!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.ingredientsHeading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (product.ingredients.isEmpty)
          Text(l10n.noIngredientsFound)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.ingredients
                .map((i) => Chip(label: Text(i.name)))
                .toList(),
          ),
        const SizedBox(height: 32),
        Text(l10n.allergensHeading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (product.allergens.isEmpty)
          Text(l10n.noAllergensFound)
        else
          ...product.allergens.map((a) => _AllergenTile(allergen: a, l10n: l10n)),
        const SizedBox(height: 32),
        Text(l10n.dietInfoHeading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (product.dietFlags.isEmpty)
          Text(l10n.valueNotAvailable)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.dietFlags
                .map((d) => Chip(
                      avatar: const Icon(Icons.eco_outlined, size: 18),
                      label: Text(LabelSpeech.dietFlagLabel(l10n, d.type)),
                    ))
                .toList(),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _AllergenTile extends StatelessWidget {
  const _AllergenTile({required this.allergen, required this.l10n});
  final AllergenEntry allergen;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = allergen.declared ? l10n.allergenDeclared : l10n.allergenInferred;
    final color = allergen.declared ? theme.colorScheme.error : theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '${allergen.name}, $badge',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(allergen.declared ? Icons.warning_amber_rounded : Icons.help_outline, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(allergen.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    Text(badge, style: theme.textTheme.bodySmall?.copyWith(color: color)),
                    Text(
                      ProvenanceLabel.spokenText(l10n, allergen.name, allergen.provenance),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
