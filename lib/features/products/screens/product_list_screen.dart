import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_list_provider.dart';
import 'widgets/product_card.dart';

/// Home screen showing the product discovery list.
///
/// Matches `docs/designs/home_explore.png`:
/// - Greeting with user's first name
/// - Search bar (non-functional in MVP)
/// - Category chips (horizontal scroll)
/// - Harita/Liste toggle
/// - "Yakınındakiler" section header
/// - Scrollable product cards
class ProductListScreen extends ConsumerWidget {
  /// Creates the [ProductListScreen].
  const ProductListScreen({super.key});

  /// Category chip definitions.
  ///
  /// Each entry maps a Turkish label to the database filter value.
  /// Pastane maps to both 'pastry' and 'dessert' (comma-separated).
  /// Sürpriz Kutu uses special 'surprise_box' filter on listing_type.
  static const List<_CategoryChip> _categories = [
    _CategoryChip(label: 'Tümü', filterValue: null),
    _CategoryChip(label: 'Fırın', filterValue: 'bread'),
    _CategoryChip(label: 'Kafe', filterValue: 'drink'),
    _CategoryChip(label: 'Pastane', filterValue: 'pastry,dessert'),
    _CategoryChip(label: 'Sürpriz Kutu', filterValue: 'surprise_box'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final filteredProducts = ref.watch(filteredProductListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- Top section: greeting + search ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    // Greeting
                    _buildGreeting(context, currentUser),
                    const SizedBox(height: AppSpacing.md),
                    // Search bar (non-functional)
                    _buildSearchBar(context),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            // --- Category chips ---
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final chip = _categories[index];
                    final isSelected = selectedCategory == chip.filterValue;
                    return _buildCategoryChip(context, ref, chip, isSelected);
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // --- Harita / Liste toggle ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildViewToggle(context),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // --- "Yakınındakiler" section header ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Yakınındakiler',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // --- Product cards ---
            filteredProducts.when(
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.hintText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Şu an yakınında aktif ürün bulunmuyor',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.hintText),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: products[index],
                        onTap: () =>
                            context.push('/product/${products[index].id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Ürünler yüklenirken bir hata oluştu.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(productListProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }

  /// Builds the greeting text with user's first name.
  Widget _buildGreeting(BuildContext context, AsyncValue<dynamic> currentUser) {
    final firstName = currentUser.whenOrNull(
      data: (user) {
        if (user == null) return null;
        final fullName = user.fullName as String?;
        if (fullName == null || fullName.isEmpty) return null;
        return fullName.split(' ').first;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba,',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
        ),
        Text(
          firstName ?? 'Kullanıcı',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  /// Builds the non-functional search bar.
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama yakında eklenecek')),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.hintText, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ürün veya işletme ara...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a category chip.
  Widget _buildCategoryChip(
    BuildContext context,
    WidgetRef ref,
    _CategoryChip chip,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = chip.filterValue;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          chip.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onBackground,
          ),
        ),
      ),
    );
  }

  /// Builds the Harita / Liste toggle buttons.
  Widget _buildViewToggle(BuildContext context) {
    return Row(
      children: [
        // Liste (active)
        Expanded(
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: Text(
              'Liste',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ),
        // Harita (non-functional)
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Harita görünümü yakında eklenecek'),
                ),
              );
            },
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Harita',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.onBackground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Internal data class for category chip definitions.
class _CategoryChip {
  const _CategoryChip({required this.label, required this.filterValue});

  /// Turkish display label for the chip.
  final String label;

  /// Database filter value, or `null` for "Tümü".
  final String? filterValue;
}
