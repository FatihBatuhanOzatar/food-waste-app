import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_list_provider.dart';
import '../providers/business_provider.dart';

/// Business owner dashboard screen.
///
/// Displays summary statistics, quick actions, and active products.
/// Matches the design in `docs/designs/business_dashboard.png`.
///
/// When [productsOnly] is true, shows only the products list
/// (used by the Ürünlerim tab in BusinessScaffold).
class BusinessDashboardScreen extends ConsumerWidget {
  /// Creates the [BusinessDashboardScreen].
  const BusinessDashboardScreen({super.key, this.productsOnly = false});

  /// If true, only show the products list without dashboard cards.
  final bool productsOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: businessAsync.when(
          data: (business) {
            if (business == null) {
              return const Center(child: Text('İşletme bulunamadı.'));
            }

            final user = userAsync.valueOrNull;
            final ownerName = user?.fullName ?? 'İşletme Sahibi';

            if (productsOnly) {
              return _ProductsFullView(businessId: business.id);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(myBusinessProvider);
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(businessProductsProvider(business.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Top bar: business name + settings gear
                    _TopBar(businessName: business.name),
                    const SizedBox(height: AppSpacing.lg),
                    // Greeting
                    Text(
                      'Merhaba, $ownerName',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'İşler bugün nasıl gidiyor?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.hintText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Summary cards
                    _DashboardCards(businessId: business.id),
                    const SizedBox(height: AppSpacing.lg),
                    // Quick add product button
                    _QuickAddButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.productCreate),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Active products section
                    _ActiveProductsSection(businessId: business.id),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(ErrorHandler.toUserMessage(e))),
        ),
      ),
    );
  }
}

/// Top bar with business name and settings gear icon.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.businessName});

  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.primary, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(
              businessName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: AppColors.onBackground),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ayarlar yakında eklenecek.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 2x2 grid of dashboard summary cards.
class _DashboardCards extends ConsumerWidget {
  const _DashboardCards({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final todaySalesCount = stats['todaySalesCount'] as int? ?? 0;
        final todaySalesAmount =
            (stats['todaySalesAmount'] as num?)?.toDouble() ?? 0.0;
        final pendingOrdersCount = stats['pendingOrdersCount'] as int? ?? 0;
        final activeProductCount = stats['activeProductCount'] as int? ?? 0;
        final totalFoodSavedKg =
            (stats['totalFoodSavedKg'] as num?)?.toDouble() ?? 0.0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.point_of_sale,
                    iconBackgroundColor: AppColors.secondary,
                    label: 'Bugünkü Satış',
                    value: '₺${todaySalesAmount.toStringAsFixed(0)}',
                    subtitle: '$todaySalesCount Satış',
                    subtitleColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.shopping_bag_outlined,
                    iconBackgroundColor: AppColors.onPrimary,
                    label: 'Bekleyen Siparişler',
                    value: '$pendingOrdersCount Sipariş',
                    subtitle: pendingOrdersCount > 0 ? 'Acil' : '',
                    subtitleColor: AppColors.onPrimary,
                    isHighlighted: pendingOrdersCount > 0,
                    showUrgencyBadge: pendingOrdersCount > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.inventory_2_outlined,
                    iconBackgroundColor: AppColors.secondary,
                    label: 'Aktif Ürünler',
                    value: '$activeProductCount Ürün',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.eco,
                    iconBackgroundColor: AppColors.semanticGreen.withValues(
                      alpha: 0.2,
                    ),
                    label: 'Kurtarılan Yemek',
                    value: '${totalFoodSavedKg.toStringAsFixed(1)} kg',
                    subtitle: 'Bu hafta',
                    subtitleColor: AppColors.semanticGreen,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Text(ErrorHandler.toUserMessage(e)),
    );
  }
}

/// Individual summary card for the dashboard.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.isHighlighted = false,
    this.showUrgencyBadge = false,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final bool isHighlighted;
  final bool showUrgencyBadge;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHighlighted ? AppColors.primary : AppColors.surface;
    final textColor = isHighlighted
        ? AppColors.onPrimary
        : AppColors.onBackground;
    final iconColor = isHighlighted ? AppColors.onPrimary : AppColors.primary;
    final iconBg = isHighlighted
        ? AppColors.onPrimary.withValues(alpha: 0.2)
        : iconBackgroundColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isHighlighted
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (showUrgencyBadge)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: subtitleColor ?? textColor,
                    ),
                  ),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtitleColor ?? textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-width terracotta button for quick product creation.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, color: AppColors.onPrimary),
        label: Text(
          '+ Hızlı Ürün Ekle',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.onPrimary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Active products section with header and product cards.
class _ActiveProductsSection extends ConsumerWidget {
  const _ActiveProductsSection({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(businessProductsProvider(businessId));

    return Column(
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktif Ürünler',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            // "Tümünü Gör" navigates to the products tab
            // (handled by BusinessScaffold tab switching)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tüm ürünleri görmek için "Ürünlerim" sekmesini kullanın.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Tümünü Gör',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Product cards
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return _EmptyProductsCard();
            }
            // Show max 3 products on dashboard
            final displayProducts = products.take(3).toList();
            return Column(
              children: displayProducts
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _BusinessProductCard(product: p),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text(ErrorHandler.toUserMessage(e)),
        ),
      ],
    );
  }
}

/// Empty state card when no products exist.
class _EmptyProductsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.hintText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Henüz ürün eklenmemiş',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"Hızlı Ürün Ekle" butonuyla ilk ürününüzü ekleyin.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Product card for the business dashboard.
class _BusinessProductCard extends StatelessWidget {
  const _BusinessProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isActive = product.status == 'active' && product.stock > 0;
    final statusText = isActive ? 'AKTİF' : 'TÜKENDİ';
    final statusColor = isActive ? AppColors.semanticGreen : AppColors.hintText;

    return Container(
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
          // Product image placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood,
              color: AppColors.hintText.withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '₺${product.currentPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '• ${product.stock} Adet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.hintText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.hintText.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: () {
              context.pushNamed(
                RouteNames.productEdit,
                pathParameters: {'id': product.id},
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Full-screen products view for the Ürünlerim tab.
class _ProductsFullView extends ConsumerWidget {
  const _ProductsFullView({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(businessProductsProvider(businessId));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(businessProductsProvider(businessId));
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ürünlerim',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  onPressed: () => context.pushNamed(RouteNames.productCreate),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(child: _EmptyProductsCard());
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _BusinessProductCard(product: products[index]),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  Center(child: Text(ErrorHandler.toUserMessage(e))),
            ),
          ),
        ],
      ),
    );
  }
}
