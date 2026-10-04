import 'package:equatable/equatable.dart';

enum ChatRole {
  user,
  assistant;

  static ChatRole fromJson(String value) =>
      ChatRole.values.firstWhere((v) => v.name == value, orElse: () => ChatRole.assistant);
}

class ChatMessage extends Equatable {
  final String id;
  final ChatRole role;
  final String text;
  final String language;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.language,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: ChatRole.fromJson(json['role'] as String),
        text: json['text'] as String,
        language: json['language'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  factory ChatMessage.local({required ChatRole role, required String text, required String language}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: role,
        text: text,
        language: language,
        createdAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, role, text, language, createdAt];
}

class AssistantAnswer extends Equatable {
  final String answer;
  final String language;
  final List<String> provenanceUsed;
  final bool uncertain;

  const AssistantAnswer({
    required this.answer,
    required this.language,
    required this.provenanceUsed,
    required this.uncertain,
  });

  factory AssistantAnswer.fromJson(Map<String, dynamic> json) => AssistantAnswer(
        answer: json['answer'] as String,
        language: json['language'] as String,
        provenanceUsed: (json['provenanceUsed'] as List<dynamic>? ?? []).cast<String>(),
        uncertain: json['uncertain'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [answer, language, provenanceUsed, uncertain];
}
