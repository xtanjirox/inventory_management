import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AppPlan { normal, pro }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final AppPlan plan;
  final String currency;
  final String language;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    String? id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.plan = AppPlan.normal,
    this.currency = 'USD',
    this.language = 'en',
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = (id == null || id.isEmpty) ? _uuid.v4() : id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? name,
    String? email,
    String? passwordHash,
    AppPlan? plan,
    String? currency,
    String? language,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      plan: plan ?? this.plan,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'plan': plan.name,
        'currency': currency,
        'language': language,
        'avatar_url': avatarUrl,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        plan: AppPlan.values.firstWhere(
          (p) => p.name == map['plan'],
          orElse: () => AppPlan.normal,
        ),
        currency: map['currency'] as String? ?? 'USD',
        language: map['language'] as String? ?? 'en',
        avatarUrl: map['avatar_url'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
