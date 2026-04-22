import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/business_provider.dart';

/// Business profile screen ("Profil" tab in the business scaffold).
///
/// Displays business name, category, owner info, address,
/// and a menu of settings/actions. Non-functional items show SnackBar.
/// "Çıkış Yap" triggers [AuthNotifier.logout] with a confirmation dialog.
class BusinessProfileScreen extends ConsumerWidget {
  /// Creates the [BusinessProfileScreen].
  const BusinessProfileScreen({super.key});

  /// Maps database category values to Turkish display labels.
  static const _categoryLabels = {
    'bakery': 'Fırın',
    'cafe': 'Kafe',
    'patisserie': 'Pastane',
    'other': 'Diğer',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final businessAsync = ref.watch(myBusinessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody(context, ref, userAsync, businessAsync)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> userAsync,
    AsyncValue<dynamic> businessAsync,
  ) {
    final user = userAsync.valueOrNull;
    final business = businessAsync.valueOrNull;

    if (userAsync.isLoading || businessAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (userAsync.hasError || businessAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Profil yüklenemedi.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                ref.invalidate(currentUserProvider);
                ref.invalidate(myBusinessProvider);
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final businessName = business?.name ?? 'İşletme';
    final category = business?.category ?? 'other';
    final categoryLabel = _categoryLabels[category] ?? 'Diğer';
    final ownerName = user?.fullName ?? 'İsimsiz';
    final ownerEmail = user?.email ?? '';
    final address = business?.address ?? '';
    final firstLetter = businessName.isNotEmpty
        ? businessName[0].toUpperCase()
        : 'İ';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'İşletme Profili',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Business avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              firstLetter,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Business name
          Text(
            businessName,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              categoryLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Owner and business info card
          Container(
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
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'İşletme Sahibi',
                  value: ownerName,
                ),
                const Divider(color: AppColors.outline, height: 24),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-posta',
                  value: ownerEmail,
                ),
                if (address.isNotEmpty) ...[
                  const Divider(color: AppColors.outline, height: 24),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adres',
                    value: address,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Menu items
          _buildMenuItem(
            context,
            icon: Icons.store_outlined,
            label: 'İşletme Bilgileri',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_none,
            label: 'Bildirim Ayarları',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.shield_outlined,
            label: 'Gizlilik Politikası',
            onTap: () => _showComingSoon(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            label: 'Yardım ve Destek',
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: AppSpacing.md),

          // Logout
          _buildMenuItem(
            context,
            icon: Icons.logout,
            label: 'Çıkış Yap',
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: AppSpacing.xl),

          // App version
          Text(
            'v1.0.0',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// Builds a single menu item row.
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? AppColors.error : AppColors.onBackground;
    final iconColor = isDestructive ? AppColors.error : AppColors.hintText;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: isDestructive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (!isDestructive)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.hintText,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a "coming soon" snackbar for non-functional menu items.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Shows a confirmation dialog before logging out.
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Çıkış Yap',
          style: Theme.of(
            dialogContext,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Çıkış yapmak istediğine emin misin?',
          style: Theme.of(dialogContext).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.hintText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row showing a label and value with an icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.hintText, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
