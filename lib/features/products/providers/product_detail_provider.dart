import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'product_list_provider.dart';

/// Fetches a single product by its [id].
///
/// Uses [ProductRepository.fetchProductById] to query Supabase
/// with the businesses JOIN.
///
/// TODO: Add live-updating dynamic price calculation (Supabase Realtime or timer).
final productDetailProvider = FutureProvider.family<Product, String>((ref, id) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchProductById(id);
});
