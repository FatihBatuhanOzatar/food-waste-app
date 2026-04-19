import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/price_formatter.dart';
import '../../orders/providers/order_provider.dart';
import '../models/product.dart';
import '../providers/product_detail_provider.dart';

/// Full product detail screen.
///
/// Shows product hero image, name, business info, pricing, pickup
/// window, stock info, and a "Rezerve Et" button. On reservation,
/// shows a confirmation bottom sheet then a success dialog.
class ProductDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ProductDetailScreen] for the given [productId].
  const ProductDetailScreen({required this.productId, super.key});

  /// The product ID passed via route parameter.
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        data: (product) {
          _remaining = product.remainingTime;
          return _buildContent(context, product);
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
                  'Ürün yüklenirken hata oluştu.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(productDetailProvider(widget.productId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final canReserve = product.isActive && !product.isExpired;

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: CustomScrollView(
            slivers: [
              // --- Hero image area ---
              SliverToBoxAdapter(child: _buildHeroArea(context, product)),

              // --- Product info ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.md),

                    // Product name
                    Text(
                      product.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Business name with pin
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Haritada göster yakında eklenecek'),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            product.businessName ?? 'İşletme',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            // TODO: Replace with real distance calculation.
                            '350m uzaklıkta',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.hintText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: AppSpacing.xl),

                    // Description
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      Text(
                        'Açıklama',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description!,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Divider(height: AppSpacing.xl),
                    ],

                    // Price info
                    _buildPriceSection(context, product),
                    const Divider(height: AppSpacing.xl),

                    // Pickup info
                    _buildPickupSection(context, product),
                    const Divider(height: AppSpacing.xl),

                    // Stock info
                    _buildStockSection(context, product),

                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
            ],
          ),
        ),

        // --- Bottom fixed area ---
        _buildBottomBar(context, product, canReserve),
      ],
    );
  }

  /// Large hero area with category icon and back button.
  Widget _buildHeroArea(BuildContext context, Product product) {
    final IconData icon;
    switch (product.category) {
      case 'bread':
        icon = Icons.bakery_dining;
      case 'pastry':
      case 'dessert':
        icon = Icons.cake;
      case 'drink':
        icon = Icons.local_cafe;
      case 'sandwich':
        icon = Icons.lunch_dining;
      case 'mixed_box':
        icon = Icons.inventory_2;
      default:
        icon = Icons.restaurant;
    }

    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Icon(icon, size: 80, color: AppColors.primary),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.sm,
          left: AppSpacing.sm,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.onBackground,
                size: 20,
              ),
            ),
          ),
        ),
        // Listing type badge
        Positioned(
          bottom: AppSpacing.md,
          left: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.isSurpriseBox ? 'Sürpriz Kutu' : 'Menü Ürünü',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Price information section.
  Widget _buildPriceSection(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fiyat Bilgisi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text('Orijinal fiyat: ', style: theme.textTheme.bodyMedium),
            Text(
              PriceFormatter.format(product.originalPrice),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.hintText,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.hintText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text('Güncel fiyat: ', style: theme.textTheme.bodyMedium),
            Text(
              PriceFormatter.format(product.currentPrice),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (product.discountPercent > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-%${product.discountPercent} indirim',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Pickup window section with countdown.
  Widget _buildPickupSection(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.format(product.pickupStart.toLocal());
    final endTime = timeFormat.format(product.pickupEnd.toLocal());

    _remaining = product.remainingTime;

    final String countdownText;
    final Color countdownColor;
    if (_remaining == Duration.zero) {
      countdownText = 'Süre doldu';
      countdownColor = AppColors.semanticRed;
    } else if (_remaining.inHours >= 1) {
      countdownText =
          '${_remaining.inHours}s ${_remaining.inMinutes.remainder(60)}dk kaldı';
      countdownColor = AppColors.semanticAmber;
    } else {
      countdownText = '${_remaining.inMinutes}dk kaldı';
      countdownColor = AppColors.semanticAmber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gel-al Bilgisi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppColors.hintText),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Gel-al saati: $startTime - $endTime',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: countdownColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: countdownColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Kalan süre: $countdownText',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: countdownColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Stock information section.
  Widget _buildStockSection(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stok Bilgisi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.inventory, size: 18, color: AppColors.hintText),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Kalan stok: ${product.stock}',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
        if (product.stock > 0 && product.stock <= 2) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.semanticAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppColors.semanticAmber,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Son birkaç ürün!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.semanticAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (product.stock == 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.semanticRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 16, color: AppColors.semanticRed),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Tükendi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.semanticRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Bottom bar with price and reserve button.
  Widget _buildBottomBar(
    BuildContext context,
    Product product,
    bool canReserve,
  ) {
    final theme = Theme.of(context);

    final String buttonLabel;
    if (product.stock == 0) {
      buttonLabel = 'Tükendi';
    } else if (product.isExpired) {
      buttonLabel = 'Süre Doldu';
    } else {
      buttonLabel = 'Rezerve Et';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Toplam',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.hintText,
                  ),
                ),
                Text(
                  PriceFormatter.format(product.currentPrice),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Reserve button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: canReserve
                      ? () => _showConfirmationSheet(context, product)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.secondary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: AppColors.hintText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: canReserve
                          ? AppColors.onPrimary
                          : AppColors.hintText,
                      fontWeight: FontWeight.w600,
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

  /// Shows the reservation confirmation bottom sheet.
  void _showConfirmationSheet(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.format(product.pickupStart.toLocal());
    final endTime = timeFormat.format(product.pickupEnd.toLocal());

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return Consumer(
          builder: (consumerContext, watchRef, _) {
            final actionState = watchRef.watch(orderActionProvider);
            final isLoading = actionState.isLoading;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Rezervasyonu Onayla',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Product info
                  _infoRow('Ürün', product.name, theme),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow('İşletme', product.businessName ?? 'İşletme', theme),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(
                    'Ödenecek tutar',
                    PriceFormatter.format(product.currentPrice),
                    theme,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow('Gel-al saati', '$startTime - $endTime', theme),
                  const SizedBox(height: AppSpacing.md),

                  // Payment info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.hintText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Ödeme işletmede nakit veya kartla yapılır',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.hintText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _onConfirmReservation(sheetContext, product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Onayla'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(sheetContext),
                      child: Text(
                        'İptal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Handles the confirm action from the bottom sheet.
  Future<void> _onConfirmReservation(
    BuildContext sheetContext,
    Product product,
  ) async {
    await ref.read(orderActionProvider.notifier).createReservation(product);

    if (!sheetContext.mounted) return;

    final actionState = ref.read(orderActionProvider);
    if (actionState.hasError) {
      Navigator.pop(sheetContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actionState.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      Navigator.pop(sheetContext);
      if (mounted) {
        _showSuccessDialog(context);
      }
    }
  }

  /// Shows the success dialog after reservation is created.
  void _showSuccessDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.semanticGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: AppColors.semanticGreen,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rezervasyon oluşturuldu!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Siparişlerim sayfasından takip edebilirsin',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.hintText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Pop back to home, then the user can tap Siparişlerim tab.
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper for info rows in the confirmation sheet.
  Widget _infoRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.hintText,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
