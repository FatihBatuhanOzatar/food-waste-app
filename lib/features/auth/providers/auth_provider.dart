import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

/// Provides the singleton [AuthRepository] instance.
///
/// Injects the global [SupabaseClient] so the repository can talk
/// to Supabase Auth and the `profiles` table.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

/// Streams auth state changes from Supabase.
///
/// Used by [AppRouter] to determine whether the user is authenticated
/// and trigger redirects on login/logout events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Fetches the current user's profile from the `profiles` table.
///
/// Returns `null` if no user is logged in. Invalidated by
/// [AuthNotifier] after login, register, logout, and KVKK acceptance.
final currentUserProvider = FutureProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

/// Notifier that manages auth actions (login, register, logout, acceptKvkk).
///
/// Exposes an [AsyncValue<void>] for loading/error states on auth actions,
/// consumed by screens to show progress indicators and error messages.
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

/// Manages auth actions and synchronises provider state.
///
/// Methods call into [AuthRepository] and invalidate [currentUserProvider]
/// on success so downstream consumers (router, screens) react.
class AuthNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is data (idle) — no pending auth action.
  }

  /// Signs in with [email] and [password].
  ///
  /// On success, invalidates [currentUserProvider] so the router
  /// picks up the new auth state.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signIn(email: email, password: password);
      ref.invalidate(currentUserProvider);
    });
  }

  /// Registers a new account and updates the profile.
  ///
  /// On success, invalidates [currentUserProvider].
  Future<void> register(
    String email,
    String password,
    String fullName,
    String? phone,
    String role,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      ref.invalidate(currentUserProvider);
    });
  }

  /// Signs the current user out and clears all auth-related providers.
  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.invalidate(currentUserProvider);
    });
  }

  /// Records KVKK acceptance for the current user.
  ///
  /// Reads the current user ID from [currentUserProvider] and calls
  /// [AuthRepository.acceptKvkk]. Invalidates [currentUserProvider]
  /// so the router detects the updated consent state and redirects.
  Future<void> acceptKvkk() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        throw const AuthException(
          'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        );
      }
      await repo.acceptKvkk(user.id);
      ref.invalidate(currentUserProvider);
    });
  }
}
