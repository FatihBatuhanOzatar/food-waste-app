import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/impact_provider.dart';

/// User profile screen ("Profil" tab).
///
/// Displays user information (avatar, name, email, role badge),
/// a mini impact summary, and a menu of settings/actions.
///
/// Non-functional menu items show a SnackBar placeholder.
/// "Çıkış Yap" triggers [AuthNotifier.logout] with a confirmation dialog.
class ProfileScreen extends ConsumerWidget {
  /// Creates the [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final impactAsync = ref.watch(userImpactProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final firstLetter = (user.fullName?.isNotEmpty == true)
                ? user.fullName![0].toUpperCase()
                : user.email[0].toUpperCase();

            final roleBadge = user.role == 'business' ? 'İşletme' : 'Kullanıcı';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      firstLetter,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Full name
                  Text(
                    user.fullName ?? 'İsimsiz Kullanıcı',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Email
                  Text(
                    user.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Role badge
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
                      roleBadge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mini impact summary
                  _MiniImpactSummary(
                    impactAsync: impactAsync,
                    onTap: () => _navigateToImpactTab(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Menu items
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Hesap Bilgileri',
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
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
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
                  'Profil yüklenemedi.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
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

  /// Navigates to the Etkim tab by finding the parent MainScaffold state.
  void _navigateToImpactTab(BuildContext context) {
    // Walk up widget tree to switch tab via the MainScaffold state.
    // The MainScaffold uses IndexedStack with tab index 2 = Etkim.
    // We dispatch a notification that the MainScaffold can listen to.
    _ImpactTabNotification().dispatch(context);
  }
}

/// Notification dispatched to request navigation to the Etkim tab.
class _ImpactTabNotification extends Notification {}

/// Compact impact summary showing 3 stats in a horizontal row.
class _MiniImpactSummary extends StatelessWidget {
  const _MiniImpactSummary({required this.impactAsync, required this.onTap});

  final AsyncValue<Map<String, double>> impactAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: impactAsync.when(
          data: (impact) {
            final food = impact['totalFoodSavedKg'] ?? 0.0;
            final co2 = impact['totalCo2SavedKg'] ?? 0.0;
            final money = impact['totalMoneySavedTry'] ?? 0.0;

            return Row(
              children: [
                _MiniStatBox(
                  value: '${food.toStringAsFixed(1)} kg',
                  label: 'Yemek',
                  color: AppColors.semanticGreen,
                ),
                _miniDivider(),
                _MiniStatBox(
                  value: '${co2.toStringAsFixed(1)} kg',
                  label: 'CO₂',
                  color: AppColors.semanticGreen,
                ),
                _miniDivider(),
                _MiniStatBox(
                  value: '₺${money.toStringAsFixed(0)}',
                  label: 'Tasarruf',
                  color: AppColors.primary,
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => const SizedBox(
            height: 48,
            child: Center(child: Text('Yüklenemedi')),
          ),
        ),
      ),
    );
  }

  Widget _miniDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.outline,
    );
  }
}

/// A single small stat box used inside [_MiniImpactSummary].
class _MiniStatBox extends StatelessWidget {
  const _MiniStatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
          ),
        ],
      ),
    );
  }
}
