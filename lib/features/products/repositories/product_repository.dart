import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../models/product.dart';

/// Repository for product operations backed by the Supabase `products` table.
///
/// This is the ONLY class in the products feature that talks to Supabase.
/// All methods throw [NetworkException] or [NotFoundException] on failure —
/// never raw Supabase exceptions.
class ProductRepository {
  /// Creates a [ProductRepository] backed by the given [SupabaseClient].
  ProductRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Fetches all active products, JOINed with the `businesses` table
  /// to include business name and location.
  ///
  /// Returns products sorted by creation date (newest first).
  ///
  /// Throws [NetworkException] if the query fails.
  Future<List<Product>> fetchActiveProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, businesses(name, latitude, longitude)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return data.map((json) => Product.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException('Ürünler yüklenemedi: ${e.message}');
    }
  }

  /// Fetches a single product by [id], JOINed with business data.
  ///
  /// Throws [NotFoundException] if no product matches.
  /// Throws [NetworkException] on other errors.
  Future<Product> fetchProductById(String id) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, businesses(name, latitude, longitude)')
          .eq('id', id)
          .single();

      return Product.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // PGRST116 = "JSON object requested, multiple (or no) rows returned"
        throw const NotFoundException('Ürün bulunamadı.');
      }
      throw NetworkException('Ürün yüklenemedi: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Business-side product management
  // ---------------------------------------------------------------------------

  /// Fetches all products for a specific business (all statuses).
  ///
  /// Unlike [fetchActiveProducts], this returns products in every
  /// status so the business owner can manage their full inventory.
  ///
  /// Throws [NetworkException] if the query fails.
  Future<List<Product>> getBusinessProducts(String businessId) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, businesses(name, latitude, longitude)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return data.map((json) => Product.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException('İşletme ürünleri yüklenemedi: ${e.message}');
    }
  }

  /// Creates a new product listing.
  ///
  /// Throws [NetworkException] if the insert fails.
  Future<Product> createProduct({
    required String businessId,
    required String name,
    String? description,
    required String category,
    required String listingType,
    required double originalPrice,
    required double currentPrice,
    required int stock,
    required DateTime pickupStart,
    required DateTime pickupEnd,
  }) async {
    try {
      final data = await _supabase
          .from('products')
          .insert({
            'business_id': businessId,
            'name': name,
            'description': description,
            'category': category,
            'listing_type': listingType,
            'original_price': originalPrice,
            'current_price': currentPrice,
            'stock': stock,
            'pickup_start': pickupStart.toUtc().toIso8601String(),
            'pickup_end': pickupEnd.toUtc().toIso8601String(),
            'status': 'active',
          })
          .select('*, businesses(name, latitude, longitude)')
          .single();

      return Product.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('Ürün oluşturulamadı: ${e.message}');
    }
  }

  /// Updates an existing product.
  ///
  /// Throws [NetworkException] if the update fails.
  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await _supabase
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select('*, businesses(name, latitude, longitude)')
          .single();

      return Product.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException('Ürün güncellenemedi: ${e.message}');
    }
  }

  /// Deletes a product by [productId].
  ///
  /// Throws [NetworkException] if the delete fails.
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
    } on PostgrestException catch (e) {
      throw NetworkException('Ürün silinemedi: ${e.message}');
    }
  }
}
