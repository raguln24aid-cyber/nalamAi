import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/accessibility/hands_free_loop_mixin.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../settings/application/locale_controller.dart';
import '../application/assistant_controller.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, required this.scanId, this.compareScanId, this.initialQuestion});
  final String scanId;
  final String? compareScanId;

  /// When the user asked a full question by voice on the Product Result screen (e.g. "does
  /// this contain milk?"), it's forwarded here and auto-submitted on open — so the hands-free
  /// flow is one voice turn, not "open assistant" then "repeat the question".
  final String? initialQuestion;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

/// Runs on [HandsFreeLoopMixin] so "go back", "help" and "repeat that" work here as they do
/// everywhere else, and so the microphone comes back when the user returns to this screen.
/// Anything the global layer does not claim is treated as a question and sent to the assistant
/// verbatim — on this screen, free-form speech is the point.
class _AssistantScreenState extends ConsumerState<AssistantScreen> with HandsFreeLoopMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sentInitialQuestion = false;
  bool _openingSpoken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final question = widget.initialQuestion;
    if (!_sentInitialQuestion && question != null && question.trim().isNotEmpty) {
      _sentInitialQuestion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(question, fromVoice: true));
      return;
    }
    // Opened without a question in hand (e.g. "ask a question" from the result screen): say so
    // and open the microphone, rather than presenting a silent text box.
    if (!_openingSpoken && question == null) {
      _openingSpoken = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        speakThenListen(AppLocalizations.of(context).assistantHint, onFinalResult: _onHeard);
      });
    }
  }

  @override
  void onScreenResumed() {
    if (!mounted) return;
    autoListenActive = true;
    startListening(onFinalResult: _onHeard);
  }

  void _onHeard(String text) {
    _textController.text = text;
    if (mounted) setState(() => isListening = false);
    _send(text, fromVoice: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String question, {bool fromVoice = false}) async {
    if (question.trim().isEmpty) return;
    _textController.clear();
    final language = ref.read(localeControllerProvider);

    final result = await ref.read(assistantControllerProvider(widget.scanId).notifier).ask(
          question,
          language: language,
          compareScanId: widget.compareScanId,
        );

    if (!mounted) return;
    _scrollToBottom();

    final l10n = AppLocalizations.of(context);
    if (result != null) {
      await ref.read(ttsServiceProvider).speak(result.answer, language: result.language);
      if (mounted && fromVoice && autoListenActive) await startListening(onFinalResult: _onHeard);
    } else {
      // Speak the failure as well as showing it — a user who cannot see the snackbar would
      // otherwise just be left with silence where an answer should be.
      final failure = ref.read(assistantControllerProvider(widget.scanId)).lastError;
      final message = failure?.message ?? l10n.errorGeneric;
      await ref.read(hapticServiceProvider).warning();
      await ref.read(ttsServiceProvider).speak(message, language: spokenLanguage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      if (fromVoice && autoListenActive) await startListening(onFinalResult: _onHeard);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(assistantControllerProvider(widget.scanId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistantTitle)),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            if (state.messages.isEmpty && !state.isLoadingHistory)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.assistantHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              ),
            Expanded(
              child: state.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: state.messages[index], l10n: l10n),
                    ),
            ),
            if (state.isSending) const LinearProgressIndicator(),
            _buildInputBar(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: l10n.assistantInputHint),
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          BigMicButtonSmall(
            isListening: isListening,
            onPressed: () => toggleListening(onFinalResult: _onHeard),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _send(_textController.text),
            icon: const Icon(Icons.send),
            tooltip: l10n.assistantSendButton,
          ),
        ],
      ),
    );
  }
}

/// Compact variant of BigMicButton sized for an inline toolbar rather than a full-screen CTA.
class BigMicButtonSmall extends StatelessWidget {
  const BigMicButtonSmall({super.key, required this.isListening, required this.onPressed});
  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isListening ? theme.colorScheme.errorContainer : null,
        minimumSize: const Size(56, 56),
      ),
      icon: Icon(isListening ? Icons.mic : Icons.mic_none),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.l10n});
  final ChatMessage message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final uncertain = !isUser && message.text.contains(l10n.provenanceUnverified);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: theme.textTheme.bodyLarge),
            if (uncertain) ...[
              const SizedBox(height: 6),
              Text(
                l10n.assistantUncertainNotice,
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
