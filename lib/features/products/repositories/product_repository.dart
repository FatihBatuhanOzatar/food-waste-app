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
}
