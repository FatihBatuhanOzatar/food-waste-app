import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/formatters/price_formatter.dart';
import '../../models/product.dart';

/// Reusable product card widget for the home screen listing.
///
/// Displays product image placeholder, name, business name, distance,
/// listing type badge, prices, countdown timer, and action buttons.
///
/// Matches the "Product Card" component spec in `docs/UI_GUIDELINES.md`:
/// - White surface background, 12px border radius, subtle shadow
/// - 80x80 image placeholder on the left
/// - Content stacked on the right
class ProductCard extends StatefulWidget {
  /// Creates a [ProductCard] for the given [product].
  const ProductCard({required this.product, this.onTap, super.key});

  /// The product data to display.
  final Product product;

  /// Optional tap callback for navigating to product detail.
  final VoidCallback? onTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late Timer _countdownTimer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.product.remainingTime;
    // Update countdown every 60 seconds.
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.product.remainingTime;
      });
    });
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _remaining = widget.product.remainingTime;
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image placeholder ---
            _buildImagePlaceholder(product),
            const SizedBox(width: AppSpacing.sm),

            // --- Content ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Business name + distance
                  Text(
                    // TODO: Replace hardcoded "350m" with real distance calculation using Haversine formula.
                    '${product.businessName ?? 'İşletme'} · 350m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.hintText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Listing type badge + countdown
                  Row(
                    children: [
                      _buildListingTypeBadge(context, product),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _buildCountdownBadge(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price row + Ayır button
                  Row(
                    children: [
                      // Original price crossed out
                      Text(
                        PriceFormatter.format(product.originalPrice),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.hintText,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.hintText,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Current price
                      Text(
                        PriceFormatter.format(product.currentPrice),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Ayır button — NON-FUNCTIONAL
                      _buildReserveButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the 80x80 image placeholder with a food icon.
  Widget _buildImagePlaceholder(Product product) {
    // Choose icon based on category.
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 36, color: AppColors.primary),
        ),
        // Heart/favorite icon — NON-FUNCTIONAL, just visual placeholder.
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              // NON-FUNCTIONAL placeholder.
            },
            child: Icon(
              Icons.favorite_border,
              size: 18,
              color: AppColors.onBackground.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the listing type badge ("Sürpriz Kutu" or "Menü").
  Widget _buildListingTypeBadge(BuildContext context, Product product) {
    final label = product.isSurpriseBox ? 'Sürpriz Kutu' : 'Menü';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
      ),
    );
  }

  /// Builds the countdown badge showing remaining pickup time.
  Widget _buildCountdownBadge(BuildContext context) {
    final String text;
    if (_remaining == Duration.zero) {
      text = 'Süre doldu';
    } else if (_remaining.inHours >= 1) {
      text =
          '${_remaining.inHours}s ${_remaining.inMinutes.remainder(60)}dk kaldı';
    } else {
      text = '${_remaining.inMinutes}dk kaldı';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.semanticAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 14,
            color: AppColors.semanticAmber,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              // TODO: Implement actual dynamic price tier countdown
              // format: "Xs Ydk sonra ₺Z'ye düşecek" — pending team decision on tiers.
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.semanticAmber),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "Ayır" reserve button — NON-FUNCTIONAL in MVP.
  Widget _buildReserveButton(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rezervasyon yakında eklenecek')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: const Text('Ayır'),
      ),
    );
  }
}
