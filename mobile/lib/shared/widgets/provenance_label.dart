import 'package:flutter/material.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/models/provenance.dart';

/// Renders a fact with its provenance prefix spelled out in full — never just an icon — per
/// docs/SAFETY_RULES.md rule 4. The returned [spokenText] is what TtsService should say aloud;
/// [build] renders the same content visually with a subdued caption style for the source tag.
class ProvenanceLabel extends StatelessWidget {
  const ProvenanceLabel({super.key, required this.value, required this.provenance, this.style});

  final String value;
  final ProvenanceSource provenance;
  final TextStyle? style;

  static String spokenText(AppLocalizations l10n, String value, ProvenanceSource provenance) {
    return switch (provenance) {
      ProvenanceSource.labelStated => l10n.provenanceLabelStated(value),
      ProvenanceSource.ocrDetected => l10n.provenanceOcrDetected(value),
      ProvenanceSource.aiInterpreted => l10n.provenanceAiInterpreted(value),
      ProvenanceSource.unverified => l10n.provenanceUnverified,
    };
  }

  static String _prefixOnly(AppLocalizations l10n, ProvenanceSource provenance) => switch (provenance) {
        ProvenanceSource.labelStated => l10n.provenanceLabelStated(''),
        ProvenanceSource.ocrDetected => l10n.provenanceOcrDetected(''),
        ProvenanceSource.aiInterpreted => l10n.provenanceAiInterpreted(''),
        ProvenanceSource.unverified => l10n.provenanceUnverified,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final prefix = _prefixOnly(l10n, provenance).replaceAll(':', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: style ?? theme.textTheme.bodyLarge),
        const SizedBox(height: 2),
        Text(
          prefix,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
