import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/business.dart';
import '../repositories/business_repository.dart';

/// Provides the singleton [BusinessRepository] instance.
///
/// Injects the global [SupabaseClient] so the repository can query
/// the `businesses` table.
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(Supabase.instance.client);
});

/// Fetches the current authenticated business owner's business profile.
///
/// Returns `null` if the logged-in user does not own a business.
/// Invalidated by [BusinessNotifier] after create/update actions.
final myBusinessProvider = FutureProvider<Business?>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return repo.getMyBusiness(user.id);
});

/// Fetches dashboard statistics for the current user's business.
///
/// Returns a map with todaySalesCount, todaySalesAmount,
/// pendingOrdersCount, activeProductCount, totalFoodSavedKg.
/// Returns an empty map if the user has no business.
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(businessRepositoryProvider);
  final business = await ref.watch(myBusinessProvider.future);
  if (business == null) return {};
  return repo.getDashboardStats(business.id);
});

/// Notifier that manages business create/update actions.
///
/// Exposes an [AsyncValue<void>] for loading/error states on business
/// actions, consumed by screens to show progress indicators and errors.
final businessNotifierProvider =
    AutoDisposeAsyncNotifierProvider<BusinessNotifier, void>(
      BusinessNotifier.new,
    );

/// Manages business creation and updates.
///
/// After mutations, invalidates [myBusinessProvider] and
/// [dashboardStatsProvider] so downstream consumers react.
class BusinessNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is data (idle) — no pending action.
  }

  /// Creates a new business profile for the current user.
  ///
  /// On success, invalidates [myBusinessProvider] so the router
  /// redirects to the business dashboard.
  Future<void> createBusiness({
    required String name,
    required String description,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required String category,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(businessRepositoryProvider);
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      await repo.createBusiness(
        ownerId: user.id,
        name: name,
        description: description,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category,
      );

      ref.invalidate(myBusinessProvider);
      ref.invalidate(dashboardStatsProvider);
    });
  }

  /// Updates the current user's business profile.
  ///
  /// Invalidates dependent providers after update.
  Future<void> updateBusiness(
    String businessId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(businessRepositoryProvider);
      await repo.updateBusiness(businessId, updates);

      ref.invalidate(myBusinessProvider);
      ref.invalidate(dashboardStatsProvider);
    });
  }
}
