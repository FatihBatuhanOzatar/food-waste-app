import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../models/business.dart';

/// Repository for business operations backed by the Supabase
/// `businesses` table.
///
/// This is the ONLY class in the businesses feature that talks to Supabase.
/// All methods throw [NetworkException] on failure — never raw Supabase
/// exceptions.
class BusinessRepository {
  /// Creates a [BusinessRepository] backed by the given [SupabaseClient].
  BusinessRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Gets the business owned by the given [ownerId].
  ///
  /// Returns `null` if the user does not own a business yet.
  Future<Business?> getMyBusiness(String ownerId) async {
    try {
      final data = await _supabase
          .from('businesses')
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (data == null) return null;
      return Business.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('İşletme bilgisi yüklenemedi: ${e.message}');
    }
  }

  /// Creates a new business profile.
  ///
  /// Throws [NetworkException] if the insert fails.
  Future<Business> createBusiness({
    required String ownerId,
    required String name,
    required String description,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required String category,
  }) async {
    try {
      final data = await _supabase
          .from('businesses')
          .insert({
            'owner_id': ownerId,
            'name': name,
            'description': description,
            'phone': phone,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'category': category,
          })
          .select()
          .single();

      return Business.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('İşletme oluşturulamadı: ${e.message}');
    }
  }

  /// Updates an existing business profile.
  ///
  /// Throws [NetworkException] if the update fails.
  Future<Business> updateBusiness(
    String businessId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await _supabase
          .from('businesses')
          .update(updates)
          .eq('id', businessId)
          .select()
          .single();

      return Business.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('İşletme güncellenemedi: ${e.message}');
    }
  }

  /// Gets dashboard statistics for the given [businessId].
  ///
  /// Returns a map with:
  /// - `todaySalesCount`: number of picked-up orders today
  /// - `todaySalesAmount`: total revenue from today's pickups
  /// - `pendingOrdersCount`: number of pending orders
  /// - `activeProductCount`: number of active products
  /// - `totalFoodSavedKg`: total food saved this week (kg)
  Future<Map<String, dynamic>> getDashboardStats(String businessId) async {
    try {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));

      // Today's picked-up orders.
      final todayOrders = await _supabase
          .from('orders')
          .select('price_paid')
          .eq('business_id', businessId)
          .eq('status', 'picked_up')
          .gte('picked_up_at', todayStart.toIso8601String());

      final todaySalesCount = todayOrders.length;
      var todaySalesAmount = 0.0;
      for (final order in todayOrders) {
        todaySalesAmount += (order['price_paid'] as num).toDouble();
      }

      // Pending orders count.
      final pendingOrders = await _supabase
          .from('orders')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'pending');

      final pendingOrdersCount = pendingOrders.length;

      // Active product count.
      final activeProducts = await _supabase
          .from('products')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'active');

      final activeProductCount = activeProducts.length;

      // Food saved this week (from impact_logs via orders).
      final weekOrders = await _supabase
          .from('orders')
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'picked_up')
          .gte('picked_up_at', weekStart.toIso8601String());

      // TODO: Pending team decision on food_saved_kg coefficient.
      // Using AppConstants.averageFoodWeightKg (0.8) per order for now.
      final totalFoodSavedKg = weekOrders.length * 0.8;

      return {
        'todaySalesCount': todaySalesCount,
        'todaySalesAmount': todaySalesAmount,
        'pendingOrdersCount': pendingOrdersCount,
        'activeProductCount': activeProductCount,
        'totalFoodSavedKg': totalFoodSavedKg,
      };
    } on PostgrestException catch (e) {
      throw NetworkException('İstatistikler yüklenemedi: ${e.message}');
    }
  }
}
