import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../settings/application/locale_controller.dart';

/// Shown for the moment between launch and knowing whether there is a session to restore.
///
/// It exists because silence is ambiguous. Restoring a session — and, for a returning user,
/// signing back in from the device credentials — takes a network round trip, and without this
/// the app either sat mute or started speaking the Home greeting only to be yanked to the
/// welcome screen mid-sentence. One short spoken line tells the user the app heard them open it.
class BootScreen extends ConsumerStatefulWidget {
  const BootScreen({super.key});

  @override
  ConsumerState<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends ConsumerState<BootScreen> {
  bool _spoken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_spoken) return;
    _spoken = true;
    final l10n = AppLocalizations.of(context);
    final language = ref.read(localeControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
            l10n.bootSpoken,
            language: language == 'ta' ? 'ta' : 'en',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Semantics(
        liveRegion: true,
        label: l10n.bootSpoken,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(l10n.bootVisual, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
