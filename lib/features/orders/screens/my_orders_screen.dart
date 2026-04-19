import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/price_formatter.dart';
import '../models/order.dart' as app;
import '../models/order_status.dart';
import '../providers/order_provider.dart';

/// Screen showing the current user's order history.
///
/// Displays a list of order cards with product name, business name,
/// price, status badge, date, and cancel button for pending orders.
/// Supports pull-to-refresh.
class MyOrdersScreen extends ConsumerWidget {
  /// Creates the [MyOrdersScreen].
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                'Siparişlerim',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Orders list
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(userOrdersProvider);
                      await ref.read(userOrdersProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _OrderCard(order: orders[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Siparişler yüklenirken hata oluştu.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(userOrdersProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.hintText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Henüz siparişin bulunmuyor',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
          ),
        ],
      ),
    );
  }
}

/// Individual order card widget.
class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final app.Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Use a fallback format if Turkish locale is not available.
    final formattedDate = _formatDate(order.createdAt);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productName ?? 'Ürün',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(context, order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Business name
          Text(
            order.businessName ?? 'İşletme',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.hintText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Price + date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PriceFormatter.format(order.pricePaid),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.hintText,
                ),
              ),
            ],
          ),

          // Cancel button for pending/confirmed orders
          if (order.isCancellable) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showCancelDialog(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.semanticRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Text('İptal Et'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a date for display, with a simple fallback.
  String _formatDate(DateTime date) {
    try {
      return DateFormat('d MMMM, HH:mm', 'tr_TR').format(date.toLocal());
    } catch (_) {
      return DateFormat('d MMM, HH:mm').format(date.toLocal());
    }
  }

  /// Builds a color-coded status badge.
  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    final Color bgColor;
    final Color textColor;

    switch (status) {
      case OrderStatus.pending:
        bgColor = AppColors.semanticAmber.withValues(alpha: 0.15);
        textColor = AppColors.semanticAmber;
      case OrderStatus.confirmed:
        bgColor = AppColors.semanticGreen.withValues(alpha: 0.15);
        textColor = AppColors.semanticGreen;
      case OrderStatus.pickedUp:
        bgColor = AppColors.hintText.withValues(alpha: 0.15);
        textColor = AppColors.hintText;
      case OrderStatus.cancelled:
      case OrderStatus.expired:
        bgColor = AppColors.semanticRed.withValues(alpha: 0.15);
        textColor = AppColors.semanticRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before cancelling.
  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Rezervasyonu İptal Et'),
          content: const Text(
            'Bu rezervasyonu iptal etmek istediğinden emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref
                    .read(orderActionProvider.notifier)
                    .cancelReservation(order.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.semanticRed,
              ),
              child: const Text('İptal Et'),
            ),
          ],
        );
      },
    );
  }
}
