import 'package:equatable/equatable.dart';

/// Authenticated user model backed by the `profiles` table in Supabase.
///
/// Represents both end-users (`role == 'user'`) and business owners
/// (`role == 'business'`), distinguished by the [role] field.
///
/// Equality is based on all fields via [Equatable].
class AppUser extends Equatable {
  /// Creates an [AppUser] with the given profile data.
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.kvkkAcceptedAt,
  });

  /// Creates an [AppUser] from a Supabase `profiles` table JSON response.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      kvkkAcceptedAt: json['kvkk_accepted_at'] != null
          ? DateTime.parse(json['kvkk_accepted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Unique user identifier (matches `auth.users.id`).
  final String id;

  /// User's email address.
  final String email;

  /// User's full name (optional until profile completion).
  final String? fullName;

  /// User's phone number (optional).
  final String? phone;

  /// User role — either `'user'` or `'business'`.
  final String role;

  /// Timestamp when the user accepted KVKK consent.
  ///
  /// `null` if the user has not yet accepted. The app blocks usage
  /// until this is non-null.
  final DateTime? kvkkAcceptedAt;

  /// Timestamp when the profile was created.
  final DateTime createdAt;

  /// Whether the user has accepted KVKK privacy consent.
  bool get hasAcceptedKvkk => kvkkAcceptedAt != null;

  /// Serializes this [AppUser] to a JSON map for Supabase insert/update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'kvkk_accepted_at': kvkkAcceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [AppUser] with the given fields replaced.
  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    DateTime? kvkkAcceptedAt,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      kvkkAcceptedAt: kvkkAcceptedAt ?? this.kvkkAcceptedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phone,
    role,
    kvkkAcceptedAt,
    createdAt,
  ];
}
