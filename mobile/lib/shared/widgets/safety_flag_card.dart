import 'package:flutter/material.dart';
import '../../core/models/scan.dart';
import '../../core/theme/app_theme.dart';

/// One safety finding, always shown with an explicit explanation — never a bare "⚠ warning"
/// icon — per docs/SAFETY_RULES.md rule 5. Color + icon differ by severity so a sighted
/// caregiver glancing at the screen also gets the right signal at a glance.
class SafetyFlagCard extends StatelessWidget {
  const SafetyFlagCard({super.key, required this.flag});
  final SafetyFlag flag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, semanticLevel) = switch (flag.severity) {
      SafetyFlagSeverity.critical => (theme.colorScheme.error, Icons.error, 'Critical'),
      SafetyFlagSeverity.warning => (
          AppTheme.warningColor(theme.brightness),
          Icons.warning_amber_rounded,
          'Warning',
        ),
      SafetyFlagSeverity.info => (theme.colorScheme.primary, Icons.info_outline, 'Information'),
    };

    return Semantics(
      label: '$semanticLevel: ${flag.message}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(flag.message, style: theme.textTheme.bodyLarge?.copyWith(height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }
}
