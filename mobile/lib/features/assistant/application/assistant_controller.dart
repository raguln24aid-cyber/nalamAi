import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/repositories/assistant_repository.dart';

class AssistantState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoadingHistory;
  final bool isSending;
  final Failure? lastError;

  const AssistantState({
    this.messages = const [],
    this.isLoadingHistory = false,
    this.isSending = false,
    this.lastError,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingHistory,
    bool? isSending,
    Failure? lastError,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
        isSending: isSending ?? this.isSending,
        lastError: lastError,
      );

  @override
  List<Object?> get props => [messages, isLoadingHistory, isSending, lastError];
}

/// Owns one scan's AI Food Assistant conversation. Every answer comes from the backend, which
/// constrains the model to the extracted product JSON and runs a deterministic safety-language
/// filter — see docs/SAFETY_RULES.md. This controller just orchestrates loading/sending/state.
class AssistantController extends StateNotifier<AssistantState> {
  AssistantController(this._repository, this.scanId) : super(const AssistantState()) {
    _loadHistory();
  }

  final AssistantRepository _repository;
  final String scanId;

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    final result = await _repository.getHistory(scanId);
    result.when(
      ok: (messages) => state = state.copyWith(messages: messages, isLoadingHistory: false),
      err: (_) => state = state.copyWith(isLoadingHistory: false),
    );
  }

  /// Returns the assistant's answer text + language on success, so the caller can speak it,
  /// or null on failure (the failure is left in [AssistantState.lastError]).
  Future<({String answer, String language})?> ask(
    String question, {
    String language = 'auto',
    String? compareScanId,
  }) async {
    final userMessage = ChatMessage.local(role: ChatRole.user, text: question, language: language);
    state = state.copyWith(messages: [...state.messages, userMessage], isSending: true, lastError: null);

    final result = await _repository.query(
      scanId: scanId,
      question: question,
      language: language,
      compareScanId: compareScanId,
    );

    return result.when(
      ok: (answer) {
        final assistantMessage = ChatMessage.local(
          role: ChatRole.assistant,
          text: answer.answer,
          language: answer.language,
        );
        state = state.copyWith(messages: [...state.messages, assistantMessage], isSending: false);
        return (answer: answer.answer, language: answer.language);
      },
      err: (failure) {
        state = state.copyWith(isSending: false, lastError: failure);
        return null;
      },
    );
  }
}

final assistantControllerProvider =
    StateNotifierProvider.autoDispose.family<AssistantController, AssistantState, String>((ref, scanId) {
  return AssistantController(ref.watch(assistantRepositoryProvider), scanId);
});
