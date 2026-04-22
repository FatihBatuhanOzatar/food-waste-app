import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/impact_provider.dart';

/// Environmental impact dashboard screen ("Etkim" tab).
///
/// Displays the user's cumulative impact from food waste prevention:
/// - Food saved (kg)
/// - CO₂ prevented (kg)
/// - Money saved (₺)
///
/// Also lists recent impact activity logs pulled from the `impact_logs`
/// table joined with order/product data.
class ImpactDashboardScreen extends ConsumerWidget {
  /// Creates the [ImpactDashboardScreen].
  const ImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impactAsync = ref.watch(userImpactProvider);
    final recentLogsAsync = ref.watch(recentImpactLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(userImpactProvider);
            ref.invalidate(recentImpactLogsProvider);
            await ref.read(userImpactProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              // Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'Etkim',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Impact metrics cards
              impactAsync.when(
                data: (impact) => _buildMetricCards(context, impact),
                loading: () =>
                    const SliverToBoxAdapter(child: _MetricCardsShimmer()),
                error: (e, _) => SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: 'Etki verileri yüklenemedi.',
                    onRetry: () => ref.invalidate(userImpactProvider),
                  ),
                ),
              ),

              // Section header: Son Aktiviteler
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Son Aktiviteler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Recent activity list
              recentLogsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        onExplore: () {
                          // Navigate to home tab (index 0) via parent scaffold
                          _navigateToHomeTab(context);
                        },
                      ),
                    );
                  }
                  return _buildActivityList(context, logs);
                },
                loading: () =>
                    const SliverToBoxAdapter(child: _ActivityListShimmer()),
                error: (e, _) => SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: 'Aktiviteler yüklenemedi.',
                    onRetry: () => ref.invalidate(recentImpactLogsProvider),
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the three vertically stacked metric cards.
  SliverToBoxAdapter _buildMetricCards(
    BuildContext context,
    Map<String, double> impact,
  ) {
    final foodKg = impact['totalFoodSavedKg'] ?? 0.0;
    final co2Kg = impact['totalCo2SavedKg'] ?? 0.0;
    final moneyTry = impact['totalMoneySavedTry'] ?? 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            _MetricCard(
              value: foodKg.toStringAsFixed(1),
              unit: 'kg kurtarılan yemek',
              icon: Icons.restaurant,
              accentColor: AppColors.semanticGreen,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricCard(
              value: co2Kg.toStringAsFixed(1),
              unit: 'kg önlenen CO₂',
              icon: Icons.cloud_outlined,
              accentColor: AppColors.semanticGreen,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricCard(
              value: '₺${moneyTry.toStringAsFixed(0)}',
              unit: 'tasarruf edilen',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the sliver list of recent activity logs.
  SliverList _buildActivityList(
    BuildContext context,
    List<Map<String, dynamic>> logs,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final log = logs[index];
        return _ActivityLogTile(log: log);
      }, childCount: logs.length),
    );
  }

  /// Navigates to the home (Keşfet) tab by finding the parent scaffold
  /// state and switching the tab index.
  void _navigateToHomeTab(BuildContext context) {
    // Walk up to find the MainScaffold's StatefulWidget state
    // and switch to index 0 (Keşfet tab).
    final scaffoldState = context.findAncestorStateOfType<State>();
    if (scaffoldState != null && scaffoldState.mounted) {
      // Use the bottom nav callback pattern via a notification
      _HomeTabNotification().dispatch(context);
    }
  }
}

/// Notification dispatched to request navigation to the home tab.
class _HomeTabNotification extends Notification {}

/// A single large metric card showing an impact value.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
  });

  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  unit,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
        ],
      ),
    );
  }
}

/// A single activity log tile showing product name, date, and savings.
class _ActivityLogTile extends StatelessWidget {
  const _ActivityLogTile({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    // Extract nested product data from the JOIN.
    final orders = log['orders'] as Map<String, dynamic>?;
    final products = orders?['products'] as Map<String, dynamic>?;
    final productName = products?['name'] as String? ?? 'Ürün';

    final foodKg = (log['food_saved_kg'] as num?)?.toDouble() ?? 0.0;
    final moneyTry = (log['money_saved_try'] as num?)?.toDouble() ?? 0.0;
    final createdAt = log['created_at'] != null
        ? DateTime.tryParse(log['created_at'] as String)
        : null;

    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy', 'tr_TR').format(createdAt)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product icon placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.semanticGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.semanticGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Product name and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
                  ),
                ],
              ),
            ),

            // Amount saved
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${foodKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.semanticGreen,
                  ),
                ),
                Text(
                  '₺${moneyTry.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when the user has no impact logs yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 64,
            color: AppColors.hintText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Henüz bir etkin yok.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'İlk siparişini vererek gıda israfını\nönlemeye başla!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Keşfet'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for metric cards while loading.
class _MetricCardsShimmer extends StatelessWidget {
  const _MetricCardsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Shimmer placeholder for activity list while loading.
class _ActivityListShimmer extends StatelessWidget {
  const _ActivityListShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Error card with retry button.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
