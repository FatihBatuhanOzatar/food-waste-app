import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Repository for authentication operations backed by Supabase Auth
/// and the `profiles` table.
///
/// This is the ONLY class in the auth feature that talks to Supabase.
/// All methods throw [AuthException] or [NetworkException] on failure —
/// never raw Supabase exceptions.
class AuthRepository {
  /// Creates an [AuthRepository] backed by the given [SupabaseClient].
  AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Signs up a new user with email and password, then updates the
  /// auto-created `profiles` row with [fullName], [phone], and [role].
  ///
  /// The database trigger creates a bare profile on signup; this method
  /// immediately fills in the extended fields.
  ///
  /// Throws [AuthException] if the signup or profile update fails.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.',
        );
      }

      // Update the auto-created profile row with extended fields.
      await _supabase
          .from('profiles')
          .update({'full_name': fullName, 'phone': phone, 'role': role})
          .eq('id', user.id);

      return await _fetchProfile(user.id);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } on PostgrestException catch (e) {
      throw NetworkException('Profil güncellenirken hata oluştu: ${e.message}');
    }
  }

  /// Signs in an existing user with email and password, then fetches
  /// the user's profile from the `profiles` table.
  ///
  /// Throws [AuthException] if credentials are invalid or the profile
  /// cannot be loaded.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Invalid login credentials');
      }

      return await _fetchProfile(user.id);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Signs the current user out.
  ///
  /// Throws [AuthException] if the sign-out fails.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Returns the current authenticated user's profile, or `null`
  /// if no user is logged in.
  ///
  /// Does NOT throw — returns `null` for unauthenticated state.
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final userId = session.user.id;
      return await _fetchProfile(userId);
    } on AuthApiException {
      return null;
    } on PostgrestException {
      return null;
    }
  }

  /// Updates the `kvkk_accepted_at` timestamp for the given [userId].
  ///
  /// Throws [NetworkException] if the update fails.
  Future<void> acceptKvkk(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'kvkk_accepted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw NetworkException('KVKK onayı kaydedilemedi: ${e.message}');
    }
  }

  /// Updates profile fields for the given [userId].
  ///
  /// Throws [NetworkException] if the update fails.
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', userId);
      }
    } on PostgrestException catch (e) {
      throw NetworkException('Profil güncellenemedi: ${e.message}');
    }
  }

  /// Stream of auth state changes for reactive listening.
  ///
  /// Used by providers and the router to react to login/logout events.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Fetches a user profile from the `profiles` table by [userId].
  Future<AppUser> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return AppUser.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('Profil yüklenemedi: ${e.message}');
    }
  }
}
