import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

/// Provides the singleton [ProductRepository] instance.
///
/// Injects the global [SupabaseClient] so the repository can query
/// the `products` table.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(Supabase.instance.client);
});

/// Fetches all active products from Supabase.
///
/// Returns a [List<Product>] sorted by creation date.
/// Invalidate this provider to refresh the list.
final productListProvider = FutureProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchActiveProducts();
});

/// Selected category filter state.
///
/// `null` means "Tümü" (show all products).
/// Non-null values correspond to database category values.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Filtered product list that combines [productListProvider] with
/// [selectedCategoryProvider].
///
/// When category is null → returns all products.
/// When category is a DB category (e.g. 'bread') → filters by that category.
/// Special case: 'surprise_box' filters by `listing_type` instead of `category`.
final filteredProductListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.whenData((products) {
    if (selectedCategory == null) return products;

    // Special case: surprise box filters by listing_type, not category.
    if (selectedCategory == 'surprise_box') {
      return products.where((p) => p.listingType == 'surprise_box').toList();
    }

    // Multiple categories can map to one chip (e.g. Pastane → pastry + dessert).
    final categories = selectedCategory.split(',');
    return products.where((p) => categories.contains(p.category)).toList();
  });
});
