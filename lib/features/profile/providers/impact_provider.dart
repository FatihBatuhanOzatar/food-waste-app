import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../repositories/impact_repository.dart';

/// Provides the singleton [ImpactRepository] instance.
///
/// Injects the global [SupabaseClient] so the repository can query
/// the `impact_logs` table.
final impactRepositoryProvider = Provider<ImpactRepository>((ref) {
  return ImpactRepository(Supabase.instance.client);
});

/// Fetches aggregated impact totals for the current user.
///
/// Returns a map with `totalFoodSavedKg`, `totalCo2SavedKg`,
/// and `totalMoneySavedTry`. Returns all zeros if no impact logs exist
/// or if the user is not authenticated.
final userImpactProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(impactRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return {
      'totalFoodSavedKg': 0.0,
      'totalCo2SavedKg': 0.0,
      'totalMoneySavedTry': 0.0,
    };
  }
  return repo.getUserTotalImpact(user.id);
});

/// Fetches recent impact logs for the current user.
///
/// Returns a list of impact log maps with joined product info
/// (name, image_url). Returns an empty list if user is not authenticated.
final recentImpactLogsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(impactRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return repo.getRecentImpactLogs(user.id);
});
