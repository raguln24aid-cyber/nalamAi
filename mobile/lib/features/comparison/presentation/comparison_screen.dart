import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/accessibility/voice_command_parser.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/scan.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/offline_banner.dart';

const _ordinalWords = {
  'first': 1, 'one': 1, 'second': 2, 'two': 2, 'third': 3, 'three': 3,
  'fourth': 4, 'four': 4, 'fifth': 5, 'five': 5,
};

int? _extractListIndex(String rawText) {
  final text = rawText.trim().toLowerCase();
  final digitMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(text);
  if (digitMatch != null) return int.tryParse(digitMatch.group(1)!);
  for (final entry in _ordinalWords.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return null;
}

class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key, this.scanIdA, this.scanIdB});
  final String? scanIdA;
  final String? scanIdB;

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> with HandsFreeLoopMixin<ComparisonScreen> {
  String? _selectedB;
  ScanComparison? _comparison;
  bool _loading = false;
  String? _error;
  List<ScanSummary> _pickerItems = const [];
  bool _pickerAnnounced = false;
  bool _resultAnnounced = false;

  @override
  void initState() {
    super.initState();
    _selectedB = widget.scanIdB;
    if (_selectedB != null && widget.scanIdA != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _compare());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPickerAndAnnounce());
    }
  }

  Future<void> _loadPickerAndAnnounce() async {
    if (widget.scanIdA == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(scansRepositoryProvider).listScans(limit: 30);
    if (!mounted) return;

    result.when(
      ok: (page) => setState(() {
        _pickerItems = page.items.where((s) => s.scanId != widget.scanIdA).toList();
      }),
      err: (_) {},
    );

    if (_pickerAnnounced) return;
    _pickerAnnounced = true;

    final tts = ref.read(ttsServiceProvider);
    if (_pickerItems.isEmpty) {
      await tts.speak('${l10n.comparisonSelectPrompt}. ${l10n.historyEmpty}', language: spokenLanguage);
    } else {
      final buffer = StringBuffer('${l10n.comparisonSelectPrompt}. ');
      for (var i = 0; i < _pickerItems.length && i < 8; i++) {
        buffer.write('${i + 1}: ${_pickerItems[i].productName ?? l10n.unknownProduct}. ');
      }
      await tts.speak(buffer.toString(), language: spokenLanguage);
    }
    if (mounted && autoListenActive) await startListening(onFinalResult: _handlePickerVoiceCommand);
  }

  Future<void> _handlePickerVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);

    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }

    final index = _extractListIndex(text);
    if (index != null && index >= 1 && index <= _pickerItems.length) {
      setState(() => _selectedB = _pickerItems[index - 1].scanId);
      await _compare();
      return;
    }

    final l10n = AppLocalizations.of(context);
    await ref.read(ttsServiceProvider).speak(l10n.comparisonSelectPrompt, language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handlePickerVoiceCommand);
  }

  Future<void> _compare() async {
    if (widget.scanIdA == null || _selectedB == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(scansRepositoryProvider)
        .compareScans(scanIdA: widget.scanIdA!, scanIdB: _selectedB!);
    if (!mounted) return;
    await result.when(
      ok: (comparison) async {
        setState(() {
          _comparison = comparison;
          _loading = false;
        });
        await _announceResult(comparison);
      },
      err: (failure) async => setState(() {
        _error = failure.message;
        _loading = false;
      }),
    );
  }

  Future<void> _announceResult(ScanComparison comparison) async {
    if (_resultAnnounced) return;
    _resultAnnounced = true;
    final l10n = AppLocalizations.of(context);
    final text = comparison.differences.isEmpty
        ? l10n.comparisonNoDifferences
        : comparison.differences.map((d) => d.note).join('. ');
    await ref.read(ttsServiceProvider).speak(text, language: spokenLanguage);
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleResultVoiceCommand);
  }

  Future<void> _handleResultVoiceCommand(String text) async {
    if (!mounted) return;
    setState(() => isListening = false);
    if (CommonVoiceCommands.isBack(text) || CommonVoiceCommands.isHome(text)) {
      context.go(AppRoutes.home);
      return;
    }
    if (VoiceCommandParser.parse(text) == VoiceCommand.repeatLast) {
      await ref.read(ttsServiceProvider).repeatLast();
    }
    if (mounted && autoListenActive) await startListening(onFinalResult: _handleResultVoiceCommand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comparisonTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: _buildBody(context, l10n)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleListening(
          onFinalResult: _selectedB == null ? _handlePickerVoiceCommand : _handleResultVoiceCommand,
        ),
        tooltip: isListening ? l10n.micListeningLabel : l10n.micIdleLabel,
        backgroundColor: isListening ? Theme.of(context).colorScheme.error : null,
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (widget.scanIdA == null) {
      return Center(child: Text(l10n.errorGeneric));
    }
    if (_selectedB == null) {
      return _ScanPickerList(
        items: _pickerItems,
        prompt: l10n.comparisonSelectPrompt,
        onSelected: (id) {
          setState(() => _selectedB = id);
          _compare();
        },
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_comparison == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final comparison = _comparison!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: Text(comparison.a.product?.name ?? l10n.unknownProduct, style: theme.textTheme.titleMedium)),
            const SizedBox(width: 12),
            Expanded(child: Text(comparison.b.product?.name ?? l10n.unknownProduct, style: theme.textTheme.titleMedium)),
          ],
        ),
        const Divider(height: 32),
        if (comparison.differences.isEmpty)
          Text(l10n.comparisonNoDifferences)
        else
          ...comparison.differences.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(d.note, style: theme.textTheme.bodyLarge),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ScanPickerList extends StatelessWidget {
  const _ScanPickerList({required this.items, required this.prompt, required this.onSelected});
  final List<ScanSummary> items;
  final String prompt;
  final void Function(String scanId) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(prompt, textAlign: TextAlign.center),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(l10n.historyEmpty))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(item.productName ?? l10n.unknownProduct),
                      subtitle: item.brand != null ? Text(item.brand!) : null,
                      onTap: () => onSelected(item.scanId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
