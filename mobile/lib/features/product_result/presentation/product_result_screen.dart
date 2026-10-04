import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/label_speech.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/safety_flag_card.dart';
import '../application/scan_detail_provider.dart';

class ProductResultScreen extends ConsumerStatefulWidget {
  const ProductResultScreen({super.key, required this.scanId});
  final String scanId;

  @override
  ConsumerState<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends ConsumerState<ProductResultScreen>
    with HandsFreeLoopMixin<ProductResultScreen> {
  bool _announced = false;

  /// Speaks a short pros/cons summary, then opens the mic so the user can ask about anything
  /// else (a question goes to the AI Assistant; "ingredients"/"nutrition"/"compare" navigate —
  /// see [_handleVoiceCommand]). Full details are no longer read unprompted.
  Future<void> _announce(Scan scan, AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    final tts = ref.read(ttsServiceProvider);
    final haptics = ref.read(hapticServiceProvider);

    if (scan.hasCriticalFlag) {
      await haptics.critical();
    } else if (scan.safetyFlags.any((f) => f.severity == SafetyFlagSeverity.warning)) {
      await haptics.warning();
    } else if (scan.safetyFlags.isNotEmpty) {
      await haptics.infoNotice();
    }

    // Pros/cons and important points first; details only when the user asks.
    await tts.speak(LabelSpeech.summary(scan, l10n), language: spokenLanguage);
    if (!mounted) return;
    await tts.speak(l10n.summaryAskPrompt, language: spokenLanguage);

    if (mounted && autoListenActive) {
      await startListening(onFinalResult: (text) => _handleVoiceCommand(text));
    }
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final command = ProductResultVoiceParser.parse(text);
    final tts = ref.read(ttsServiceProvider);

    switch (command) {
      case ProductResultCommand.viewNutrition:
        context.push(AppRoutes.nutritionPath(widget.scanId));
        return;
      case ProductResultCommand.viewIngredients:
        context.push(AppRoutes.ingredientsPath(widget.scanId));
        return;
      case ProductResultCommand.compare:
        context.push('${AppRoutes.comparison}?a=${widget.scanId}');
        return;
      case ProductResultCommand.rescan:
        context.pushReplacement(AppRoutes.scanner);
        return;
      case ProductResultCommand.askQuestion:
        // Forward the exact wording so the assistant answers this turn, not an empty screen.
        context.push(AppRoutes.assistantPath(widget.scanId), extra: text);
        return;
      case ProductResultCommand.repeatLast:
        await tts.repeatLast();
      case ProductResultCommand.unknown:
        final l10n = AppLocalizations.of(context);
        await tts.speak(l10n.assistantHint, language: spokenLanguage);
    }

    if (mounted && autoListenActive) {
      await startListening(onFinalResult: (t) => _handleVoiceCommand(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanAsync = ref.watch(scanDetailProvider(widget.scanId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productResultTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            if (isListening)
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.micListeningLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            Expanded(
              child: scanAsync.when(
                data: (scan) {
                  if (scan == null) {
                    return Center(child: Text(l10n.errorGeneric));
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) => _announce(scan, l10n));
                  return _buildContent(context, l10n, scan);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(l10n.errorGeneric)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleListening(onFinalResult: (t) => _handleVoiceCommand(t)),
        tooltip: isListening ? l10n.micListeningLabel : l10n.micIdleLabel,
        backgroundColor: isListening ? Theme.of(context).colorScheme.error : null,
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, Scan scan) {
    final theme = Theme.of(context);
    final product = scan.product;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          header: true,
          child: Text(
            product?.name ?? l10n.unknownProduct,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (product?.brand != null) ...[
          const SizedBox(height: 4),
          Text(product!.brand!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        Text(l10n.safetyFlagsHeading, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (scan.safetyFlags.isEmpty)
          Text(l10n.noSafetyFlags, style: theme.textTheme.bodyMedium)
        else
          ...scan.safetyFlags.map((f) => SafetyFlagCard(flag: f)),
        const SizedBox(height: 32),
        _ActionButton(
          icon: Icons.restaurant_menu,
          label: l10n.viewNutritionDetails,
          onPressed: () => context.push(AppRoutes.nutritionPath(scan.scanId)),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.list_alt,
          label: l10n.viewIngredientsAllergens,
          onPressed: () => context.push(AppRoutes.ingredientsPath(scan.scanId)),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: l10n.askAssistantButton,
          onPressed: () => context.push(AppRoutes.assistantPath(scan.scanId)),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.compare_arrows,
          label: l10n.compareWithAnother,
          onPressed: () => context.push('${AppRoutes.comparison}?a=${scan.scanId}'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.pushReplacement(AppRoutes.scanner),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(l10n.rescanButton),
        ),
        const SizedBox(height: 80), // keep content clear of the floating mic button
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icon), label: Align(
      alignment: Alignment.centerLeft,
      child: Text(label),
    ));
  }
}
