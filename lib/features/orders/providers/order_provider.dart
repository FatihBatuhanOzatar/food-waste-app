import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_list_provider.dart';
import '../models/order.dart' as app;
import '../repositories/order_repository.dart';

/// Provides the singleton [OrderRepository] instance.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Supabase.instance.client);
});

/// Fetches the current user's orders, newest first.
///
/// Automatically gets the user ID from [currentUserProvider].
/// Returns an empty list if the user is not logged in.
/// Invalidated by [OrderNotifier] after mutations.
final userOrdersProvider = FutureProvider<List<app.Order>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return repo.getUserOrders(user.id);
});

/// Notifier that manages order actions (create, cancel).
///
/// Exposes an [AsyncValue<void>] for loading/error states on order
/// actions, consumed by screens to show progress indicators and errors.
final orderActionProvider =
    AutoDisposeAsyncNotifierProvider<OrderNotifier, void>(OrderNotifier.new);

/// Manages order creation and cancellation.
///
/// After mutations, invalidates [userOrdersProvider] and
/// [productListProvider] (since stock changes affect the home screen).
class OrderNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is data (idle) — no pending action.
  }

  /// Creates a reservation for the given [product].
  ///
  /// Gets the current user from [currentUserProvider], calls
  /// [OrderRepository.createReservation], then invalidates
  /// dependent providers so the UI refreshes.
  Future<void> createReservation(Product product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(orderRepositoryProvider);
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      await repo.createReservation(
        userId: user.id,
        productId: product.id,
        businessId: product.businessId,
        pricePaid: product.currentPrice,
        originalPrice: product.originalPrice,
      );

      // Refresh the orders list and product list (stock changed).
      ref.invalidate(userOrdersProvider);
      ref.invalidate(productListProvider);
    });
  }

  /// Cancels an existing reservation by [orderId].
  ///
  /// Invalidates dependent providers after cancellation.
  Future<void> cancelReservation(String orderId, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(orderRepositoryProvider);
      await repo.cancelReservation(orderId, reason: reason);

      // Refresh both orders and products (stock restored).
      ref.invalidate(userOrdersProvider);
      ref.invalidate(productListProvider);
    });
  }
}
