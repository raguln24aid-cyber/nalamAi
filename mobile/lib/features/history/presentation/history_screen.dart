import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../application/history_provider.dart';

const _ordinalWords = {
  'first': 1, 'one': 1, 'second': 2, 'two': 2, 'third': 3, 'three': 3,
  'fourth': 4, 'four': 4, 'fifth': 5, 'five': 5, 'sixth': 6, 'six': 6,
  'seventh': 7, 'seven': 7, 'eighth': 8, 'eight': 8, 'ninth': 9, 'nine': 9,
  'tenth': 10, 'ten': 10,
};

/// Recognises "open number 2", "open the second one", "2", etc. against a spoken list —
/// deliberately simple (numerals + English ordinal words) rather than a full NLU parser, same
/// keyword-based philosophy as the rest of core/accessibility/voice_command_parser.dart.
int? _extractListIndex(String rawText) {
  final text = rawText.trim().toLowerCase();
  final digitMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(text);
  if (digitMatch != null) return int.tryParse(digitMatch.group(1)!);
  for (final entry in _ordinalWords.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return null;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with HandsFreeLoopMixin<HistoryScreen> {
  bool _announced = false;
  List<ScanSummary> _lastItems = const [];

  static const _maxSpokenItems = 8;

  Future<void> _announce(List<ScanSummary> items, AppLocalizations l10n) async {
    if (_announced) return;
    _announced = true;
    _lastItems = items;
    final tts = ref.read(ttsServiceProvider);

    if (items.isEmpty) {
      await tts.speak(l10n.historyEmpty, language: spokenLanguage);
      if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
      return;
    }

    final buffer = StringBuffer('${items.length}. ');
    for (var i = 0; i < items.length && i < _maxSpokenItems; i++) {
      final item = items[i];
      buffer.write('${i + 1}: ${item.productName ?? l10n.unknownProduct}. ');
    }
    await tts.speak(buffer.toString(), language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  Future<void> _handleVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    final tts = ref.read(ttsServiceProvider);
    final l10n = AppLocalizations.of(context);

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }

    final scanCommand = VoiceCommandParser.parse(text);
    if (scanCommand == VoiceCommand.scanProduct) {
      context.push(AppRoutes.scanner);
      return;
    }
    if (scanCommand == VoiceCommand.repeatLast) {
      await tts.repeatLast();
      if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
      return;
    }

    final index = _extractListIndex(text);
    if (index != null && index >= 1 && index <= _lastItems.length) {
      context.push(AppRoutes.resultPath(_lastItems[index - 1].scanId));
      return;
    }

    await tts.speak(l10n.historyTitle, language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: historyAsync.when(
                data: (items) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _announce(items, l10n));
                  if (items.isEmpty) return Center(child: Text(l10n.historyEmpty));
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(scanHistoryProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _HistoryTile(index: index, item: items[index], l10n: l10n),
                    ),
                  );
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
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.index, required this.item, required this.l10n});
  final int index;
  final ScanSummary item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal());
    final title = item.productName ?? l10n.unknownProduct;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.hasCriticalSafetyFlag
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text('${index + 1}'),
      ),
      title: Text(title),
      subtitle: Text('${item.brand ?? ''} • $dateLabel'.trim()),
      trailing: item.hasCriticalSafetyFlag
          ? Icon(Icons.error, color: Theme.of(context).colorScheme.error)
          : null,
      onTap: () => context.push(AppRoutes.resultPath(item.scanId)),
    );
  }
}
