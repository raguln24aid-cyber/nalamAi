import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/providers/core_providers.dart';
import '../../core/network/connectivity_service.dart';

/// Persistent banner shown across screens when the device has no connectivity, so a user who
/// cannot see the screen still gets a spoken/visual explanation for why an action isn't working
/// instead of a silent failure. See ARCHITECTURE.md "Offline" decision.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStatusProvider);
    final l10n = AppLocalizations.of(context);

    return connectivity.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return _Banner(message: l10n.offlineBannerMessage);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: colorScheme.onErrorContainer, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Not authoritative — [ConnectivityService] should be used for logic; this is only for UI reads.
extension ConnectivityLabel on bool {
  String label(AppLocalizations l10n) => this ? '' : l10n.offlineBannerMessage;
}
