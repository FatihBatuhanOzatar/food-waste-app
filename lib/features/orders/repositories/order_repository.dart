import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../models/order.dart' as app;
import '../models/order_status.dart';

/// Repository for order/reservation operations backed by the Supabase
/// `orders` table.
///
/// This is the ONLY class in the orders feature that talks to Supabase.
/// All methods throw [NetworkException] or [NotFoundException] on failure.
class OrderRepository {
  /// Creates an [OrderRepository] backed by the given [SupabaseClient].
  OrderRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Creates a new reservation (order with status 'pending').
  ///
  /// Steps:
  /// 1. Check product stock > 0
  /// 2. Insert into orders table with status 'pending'
  /// 3. Decrement product stock by 1
  /// 4. If stock hits 0, update product status to 'sold_out'
  ///
  /// TODO: These steps should ideally be in a database transaction.
  /// Supabase client SDK doesn't support transactions directly, so they
  /// run sequentially. There is a potential race condition where two users
  /// could reserve the last item simultaneously. A Postgres function or
  /// Edge Function should handle this in production.
  ///
  /// Throws [ValidationException] if stock is 0.
  /// Throws [NetworkException] on database errors.
  Future<app.Order> createReservation({
    required String userId,
    required String productId,
    required String businessId,
    required double pricePaid,
    required double originalPrice,
  }) async {
    try {
      // 1. Check product stock.
      final product = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = product['stock'] as int;
      if (currentStock <= 0) {
        throw const ValidationException('Bu ürün tükenmiştir.', field: 'stock');
      }

      // 2. Insert the order.
      final orderData = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'business_id': businessId,
            'price_paid': pricePaid,
            'original_price': originalPrice,
            'status': 'pending',
          })
          .select('*, products(name, image_url), businesses(name)')
          .single();

      // 3. Decrement stock.
      final newStock = currentStock - 1;
      final updates = <String, dynamic>{'stock': newStock};

      // 4. If stock hits 0, mark product as sold out.
      if (newStock == 0) {
        updates['status'] = 'sold_out';
      }

      await _supabase.from('products').update(updates).eq('id', productId);

      return app.Order.fromJson(orderData);
    } on ValidationException {
      rethrow;
    } on PostgrestException catch (e) {
      throw NetworkException('Rezervasyon oluşturulamadı: ${e.message}');
    }
  }

  /// Fetches all orders for a user, newest first.
  ///
  /// Includes product name and business name via JOINs.
  ///
  /// Throws [NetworkException] if the query fails.
  Future<List<app.Order>> getUserOrders(String userId) async {
    try {
      final data = await _supabase
          .from('orders')
          .select('*, products(name, image_url), businesses(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => app.Order.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException('Siparişler yüklenemedi: ${e.message}');
    }
  }

  /// Fetches all orders for a business, newest first.
  ///
  /// Throws [NetworkException] if the query fails.
  Future<List<app.Order>> getBusinessOrders(String businessId) async {
    try {
      final data = await _supabase
          .from('orders')
          .select('*, products(name, image_url), businesses(name)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return data.map((json) => app.Order.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException('İşletme siparişleri yüklenemedi: ${e.message}');
    }
  }

  /// Updates an order's status and sets the appropriate timestamp.
  ///
  /// On cancellation, also restores product stock (+1) and reactivates
  /// the product if it was sold out.
  ///
  /// Throws [NetworkException] on database errors.
  Future<app.Order> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{'status': newStatus.dbValue};

      switch (newStatus) {
        case OrderStatus.confirmed:
          updates['confirmed_at'] = now;
        case OrderStatus.pickedUp:
          updates['picked_up_at'] = now;
        case OrderStatus.cancelled:
        case OrderStatus.expired:
          updates['cancelled_at'] = now;
        case OrderStatus.pending:
          break;
      }

      final data = await _supabase
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select('*, products(name, image_url), businesses(name)')
          .single();

      final order = app.Order.fromJson(data);

      // If cancelling, restore stock.
      if (newStatus == OrderStatus.cancelled) {
        await _restoreProductStock(order.productId);
      }

      return order;
    } on PostgrestException catch (e) {
      throw NetworkException('Sipariş durumu güncellenemedi: ${e.message}');
    }
  }

  /// Cancels a reservation by the user, with an optional reason.
  ///
  /// Restores product stock and reactivates the product if needed.
  ///
  /// Throws [NetworkException] on database errors.
  Future<app.Order> cancelReservation(String orderId, {String? reason}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'status': OrderStatus.cancelled.dbValue,
        'cancelled_at': now,
      };
      if (reason != null) {
        updates['cancelled_reason'] = reason;
      }

      final data = await _supabase
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select('*, products(name, image_url), businesses(name)')
          .single();

      final order = app.Order.fromJson(data);

      // Restore stock.
      await _restoreProductStock(order.productId);

      return order;
    } on PostgrestException catch (e) {
      throw NetworkException('Rezervasyon iptal edilemedi: ${e.message}');
    }
  }

  /// Increments product stock by 1 and reactivates if it was sold out.
  Future<void> _restoreProductStock(String productId) async {
    try {
      final product = await _supabase
          .from('products')
          .select('stock, status')
          .eq('id', productId)
          .single();

      final currentStock = product['stock'] as int;
      final currentStatus = product['status'] as String;

      final updates = <String, dynamic>{'stock': currentStock + 1};
      if (currentStatus == 'sold_out') {
        updates['status'] = 'active';
      }

      await _supabase.from('products').update(updates).eq('id', productId);
    } on PostgrestException {
      // Stock restore is best-effort; log but don't fail the cancellation.
      // TODO: Add proper logging for stock restore failures.
    }
  }
}
