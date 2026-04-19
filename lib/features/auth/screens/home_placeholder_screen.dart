import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// Temporary placeholder home screen shown after successful authentication.
///
/// Displays a greeting with the user's name, their email, a role badge,
/// and a logout button. Will be replaced when the Home feature is built.
class HomePlaceholderScreen extends ConsumerWidget {
  /// Creates the [HomePlaceholderScreen].
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: currentUser.when(
            data: (user) {
              final displayName = user?.fullName ?? 'Kullanıcı';
              final email = user?.email ?? '';
              final roleBadge = user?.role == 'business'
                  ? 'İşletme'
                  : 'Kullanıcı';

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Greeting
                    Text(
                      'Hoş geldin, $displayName!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Email
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.hintText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleBadge,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Logout button
                    SizedBox(
                      width: 200,
                      child: AppButton(
                        label: 'Çıkış Yap',
                        isOutlined: true,
                        onPressed: () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .logout();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) => Center(
              child: Text(
                'Profil yüklenemedi.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
