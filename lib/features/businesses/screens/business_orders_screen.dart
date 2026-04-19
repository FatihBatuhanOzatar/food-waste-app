import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../orders/models/order.dart' as app;
import '../../orders/models/order_status.dart';
import '../../orders/providers/order_provider.dart';
import '../../products/providers/product_list_provider.dart';
import '../../profile/repositories/impact_repository.dart';
import '../providers/business_provider.dart';

/// Business-side order management screen.
///
/// Shows orders grouped by status with action buttons:
/// - Pending: Onayla / Reddet
/// - Confirmed: Teslim Edildi
/// - Picked up / Cancelled: read-only
class BusinessOrdersScreen extends ConsumerStatefulWidget {
  /// Creates the [BusinessOrdersScreen].
  const BusinessOrdersScreen({super.key});

  @override
  ConsumerState<BusinessOrdersScreen> createState() =>
      _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends ConsumerState<BusinessOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Tab filter labels.
  static const List<String> _tabLabels = [
    'Bekleyen',
    'Onaylanan',
    'Tamamlanan',
    'Tümü',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(myBusinessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: businessAsync.when(
          data: (business) {
            if (business == null) {
              return const Center(child: Text('İşletme bulunamadı.'));
            }

            return Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Siparişler',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.onPrimary,
                    unselectedLabelColor: AppColors.onBackground,
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                    unselectedLabelStyle: Theme.of(
                      context,
                    ).textTheme.labelLarge,
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(2),
                    tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Order list
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OrderList(
                        businessId: business.id,
                        statusFilter: OrderStatus.pending,
                      ),
                      _OrderList(
                        businessId: business.id,
                        statusFilter: OrderStatus.confirmed,
                      ),
                      _OrderList(
                        businessId: business.id,
                        statusFilter: OrderStatus.pickedUp,
                      ),
                      _OrderList(businessId: business.id),
                    ],
                  ),
                ),
              ],
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

/// Filtered order list for a specific status tab.
class _OrderList extends ConsumerWidget {
  const _OrderList({required this.businessId, this.statusFilter});

  final String businessId;
  final OrderStatus? statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(businessOrdersProvider(businessId));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(businessOrdersProvider(businessId));
      },
      child: ordersAsync.when(
        data: (orders) {
          final filtered = statusFilter != null
              ? orders.where((o) => o.status == statusFilter).toList()
              : orders;

          if (filtered.isEmpty) {
            return _EmptyOrderState(statusFilter: statusFilter);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OrderCard(
                  order: filtered[index],
                  businessId: businessId,
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(ErrorHandler.toUserMessage(e))),
      ),
    );
  }
}

/// Empty state for a tab with no orders.
class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState({this.statusFilter});

  final OrderStatus? statusFilter;

  @override
  Widget build(BuildContext context) {
    final message = switch (statusFilter) {
      OrderStatus.pending => 'Bekleyen sipariş yok.',
      OrderStatus.confirmed => 'Onaylanan sipariş yok.',
      OrderStatus.pickedUp => 'Tamamlanan sipariş yok.',
      _ => 'Henüz sipariş yok.',
    };

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.hintText.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual order card with action buttons.
class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order, required this.businessId});

  final app.Order order;
  final String businessId;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isActioning = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _getStatusColor(order.status);
    final timeAgo = _formatTimeAgo(order.createdAt);

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
          // Header: customer name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Müşteri',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.displayLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Product name
          Text(
            order.productName ?? 'Ürün',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Price + time
          Row(
            children: [
              Text(
                '₺${order.pricePaid.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '• $timeAgo',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
              ),
            ],
          ),
          // Action buttons
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.outline, height: 1),
            const SizedBox(height: AppSpacing.sm),
            _buildActionButtons(context, order),
          ],
        ],
      ),
    );
  }

  /// Builds action buttons based on order status.
  Widget _buildActionButtons(BuildContext context, app.Order order) {
    if (_isActioning) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => _approveOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.semanticGreen,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Onayla'),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextButton(
                onPressed: () => _showRejectDialog(order),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.semanticRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reddet'),
              ),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.confirmed) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          onPressed: () => _markPickedUp(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Teslim Edildi'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Approves a pending order.
  Future<void> _approveOrder(app.Order order) async {
    setState(() => _isActioning = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(order.id, OrderStatus.confirmed);
      ref.invalidate(businessOrdersProvider(widget.businessId));
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.toUserMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  /// Shows a dialog to reject an order with optional reason.
  Future<void> _showRejectDialog(app.Order order) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Siparişi Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu siparişi reddetmek istediğinize emin misiniz?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Ret sebebi (isteğe bağlı)',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.semanticRed,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isActioning = true);
      try {
        final repo = ref.read(orderRepositoryProvider);
        final reason = reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null;
        await repo.cancelReservation(order.id, reason: reason);
        ref.invalidate(businessOrdersProvider(widget.businessId));
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(businessProductsProvider(widget.businessId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.toUserMessage(e))),
          );
        }
      } finally {
        if (mounted) setState(() => _isActioning = false);
      }
    }

    reasonController.dispose();
  }

  /// Marks an order as picked up and creates an impact log.
  Future<void> _markPickedUp(app.Order order) async {
    setState(() => _isActioning = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(order.id, OrderStatus.pickedUp);

      // Create impact log entry.
      // TODO: Pending team decision on food_saved_kg and co2_saved_kg values.
      final impactRepo = ImpactRepository(Supabase.instance.client);
      await impactRepo.createImpactLog(
        userId: order.userId,
        orderId: order.id,
        foodSavedKg: AppConstants.averageFoodWeightKg,
        co2SavedKg: AppConstants.co2PerOrderKg,
        moneySavedTry: order.originalPrice - order.pricePaid,
      );

      ref.invalidate(businessOrdersProvider(widget.businessId));
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.toUserMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  /// Returns the color for a given order status.
  Color _getStatusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => AppColors.semanticAmber,
      OrderStatus.confirmed => AppColors.semanticGreen,
      OrderStatus.pickedUp => AppColors.primary,
      OrderStatus.cancelled => AppColors.semanticRed,
      OrderStatus.expired => AppColors.hintText,
    };
  }

  /// Formats a DateTime as a relative time string.
  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}s önce';
    return '${diff.inDays}g önce';
  }
}
