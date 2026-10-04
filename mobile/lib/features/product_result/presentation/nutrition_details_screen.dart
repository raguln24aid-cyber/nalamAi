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
import '../application/scan_detail_provider.dart';

class NutritionDetailsScreen extends ConsumerStatefulWidget {
  const NutritionDetailsScreen({super.key, required this.scanId});
  final String scanId;

  @override
  ConsumerState<NutritionDetailsScreen> createState() => _NutritionDetailsScreenState();
}

class _NutritionDetailsScreenState extends ConsumerState<NutritionDetailsScreen>
    with HandsFreeLoopMixin<NutritionDetailsScreen> {
  bool _announced = false;

  Future<void> _announce(Scan scan, AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final speech = LabelSpeech.nutrition(scan.product?.nutritionFacts, l10n) ?? l10n.valueNotAvailable;
    await ref.read(ttsServiceProvider).speak(speech, language: spokenLanguage);
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
      case ProductResultCommand.viewIngredients:
        context.push(AppRoutes.ingredientsPath(widget.scanId));
        return;
      case ProductResultCommand.rescan:
        context.pushReplacement(AppRoutes.scanner);
        return;
      case ProductResultCommand.askQuestion:
        context.push(AppRoutes.assistantPath(widget.scanId), extra: text);
        return;
      case ProductResultCommand.repeatLast:
        await tts.repeatLast();
      case ProductResultCommand.viewNutrition:
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
      appBar: AppBar(title: Text(l10n.nutritionTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: scanAsync.when(
                data: (scan) {
                  if (scan == null) return Center(child: Text(l10n.errorGeneric));
                  WidgetsBinding.instance.addPostFrameCallback((_) => _announce(scan, l10n));
                  final facts = scan.product?.nutritionFacts;
                  if (facts == null) {
                    return Center(child: Text(l10n.valueNotAvailable));
                  }
                  return _buildFacts(context, l10n, facts);
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

  Widget _buildFacts(BuildContext context, AppLocalizations l10n, NutritionFacts facts) {
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      if (facts.servingSize != null) (l10n.servingSize, facts.servingSize!),
      (l10n.calories, _fmt(facts.calories, 'kcal', l10n)),
      (l10n.sugar, _fmt(facts.sugarG, 'g', l10n)),
      (l10n.protein, _fmt(facts.proteinG, 'g', l10n)),
      (l10n.fat, _fmt(facts.fatG, 'g', l10n)),
      (l10n.saturatedFat, _fmt(facts.saturatedFatG, 'g', l10n)),
      (l10n.sodium, _fmt(facts.sodiumMg, 'mg', l10n)),
      (l10n.fiber, _fmt(facts.fiberG, 'g', l10n)),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.nutritionPer100g, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: '${row.$1}: ${row.$2}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: Text(row.$1, style: theme.textTheme.bodyLarge)),
                      Text(row.$2, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 32),
        Text(
          _provenanceLabel(l10n, facts.provenance),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  String _fmt(double? value, String unit, AppLocalizations l10n) {
    if (value == null) return l10n.valueNotAvailable;
    final rounded = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$rounded $unit';
  }

  String _provenanceLabel(AppLocalizations l10n, dynamic provenance) {
    final name = provenance.toString().split('.').last;
    return switch (name) {
      'labelStated' => l10n.provenanceLabelStated(''),
      'ocrDetected' => l10n.provenanceOcrDetected(''),
      'aiInterpreted' => l10n.provenanceAiInterpreted(''),
      _ => l10n.provenanceUnverified,
    };
  }
}
