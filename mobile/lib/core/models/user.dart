import 'package:equatable/equatable.dart';

enum AppLanguage {
  en,
  ta,
  auto;

  static AppLanguage fromJson(String value) => AppLanguage.values.firstWhere(
        (v) => v.name == value,
        orElse: () => AppLanguage.auto,
      );
}

class AppUser extends Equatable {
  final String id;
  final String email;
  final AppLanguage preferredLanguage;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.preferredLanguage,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        preferredLanguage: AppLanguage.fromJson(json['preferredLanguage'] as String),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'preferredLanguage': preferredLanguage.name,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, email, preferredLanguage, createdAt];
}

class AuthSession extends Equatable {
  final AppUser user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  @override
  List<Object?> get props => [user, accessToken, refreshToken];
}
