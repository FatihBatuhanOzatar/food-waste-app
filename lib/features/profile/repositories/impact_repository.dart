import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// Repository for impact log operations backed by the Supabase
/// `impact_logs` table.
///
/// Impact logs are created when an order is marked as picked up,
/// recording the environmental and financial impact of each transaction.
class ImpactRepository {
  /// Creates an [ImpactRepository] backed by the given [SupabaseClient].
  ImpactRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Creates an impact log entry when an order is picked up.
  ///
  /// Each order can have at most one impact log (enforced by unique
  /// constraint on `order_id`).
  ///
  /// Throws [NetworkException] if the insert fails.
  Future<void> createImpactLog({
    required String userId,
    required String orderId,
    required double foodSavedKg,
    required double co2SavedKg,
    required double moneySavedTry,
  }) async {
    try {
      await _supabase.from('impact_logs').insert({
        'user_id': userId,
        'order_id': orderId,
        'food_saved_kg': foodSavedKg,
        'co2_saved_kg': co2SavedKg,
        'money_saved_try': moneySavedTry,
      });
    } on PostgrestException catch (e) {
      throw NetworkException('Etki kaydı oluşturulamadı: ${e.message}');
    }
  }

  /// Gets aggregated impact totals for a specific user.
  ///
  /// Returns a map with keys:
  /// - `totalFoodSavedKg`: total food saved in kg
  /// - `totalCo2SavedKg`: total CO₂ emissions prevented in kg
  /// - `totalMoneySavedTry`: total money saved in ₺
  ///
  /// If no impact logs exist, all values are 0.0.
  Future<Map<String, double>> getUserTotalImpact(String userId) async {
    try {
      final data = await _supabase
          .from('impact_logs')
          .select('food_saved_kg, co2_saved_kg, money_saved_try')
          .eq('user_id', userId);

      var totalFood = 0.0;
      var totalCo2 = 0.0;
      var totalMoney = 0.0;

      for (final row in data) {
        totalFood += (row['food_saved_kg'] as num).toDouble();
        totalCo2 += (row['co2_saved_kg'] as num).toDouble();
        totalMoney += (row['money_saved_try'] as num).toDouble();
      }

      return {
        'totalFoodSavedKg': totalFood,
        'totalCo2SavedKg': totalCo2,
        'totalMoneySavedTry': totalMoney,
      };
    } on PostgrestException catch (e) {
      throw NetworkException('Etki verileri yüklenemedi: ${e.message}');
    }
  }

  /// Gets recent impact logs for a user with product info.
  ///
  /// Joins with the `orders` table and `products` table to include
  /// the product name and image URL. Returns up to [limit] rows,
  /// ordered by most recent first.
  ///
  /// Each entry in the returned list contains:
  /// - `id`, `food_saved_kg`, `co2_saved_kg`, `money_saved_try`, `created_at`
  /// - `orders.products.name`, `orders.products.image_url`
  Future<List<Map<String, dynamic>>> getRecentImpactLogs(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final data = await _supabase
          .from('impact_logs')
          .select(
            'id, food_saved_kg, co2_saved_kg, money_saved_try, created_at, '
            'orders!inner(products!inner(name, image_url))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw NetworkException('Son aktiviteler yüklenemedi: ${e.message}');
    }
  }
}
