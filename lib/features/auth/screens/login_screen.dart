import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../shared/validators/email_validator.dart';
import '../providers/auth_provider.dart';

/// Login screen matching `docs/designs/login.png`.
///
/// Displays email/password fields, sign-in button, divider with "veya",
/// Google sign-in button (non-functional in MVP), and a link to register.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Listen for errors and show them inline (error text below form).
    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      // Error handling is done inline via authState below.
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl + AppSpacing.xl),

                // Logo text
                Center(
                  child: Text(
                    'foodwasteapp',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Email field
                AppTextField(
                  controller: _emailController,
                  labelText: 'E-posta',
                  hintText: 'ornek@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: EmailValidator.validate,
                ),
                const SizedBox(height: AppSpacing.md),

                // Password field
                AppTextField(
                  controller: _passwordController,
                  labelText: 'Şifre',
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.hintText,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre boş bırakılamaz.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şifre sıfırlama yakında eklenecek.'),
                        ),
                      );
                    },
                    child: Text(
                      'Şifremi Unuttum',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Error message display
                if (authState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      ErrorHandler.toUserMessage(authState.error!),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Login button
                AppButton(
                  label: 'Giriş Yap',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Divider with "veya"
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.outline, thickness: 0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'veya',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.hintText,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.outline, thickness: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Google sign-in button (non-functional in MVP)
                AppButton(
                  label: 'Google ile Giriş Yap',
                  isOutlined: true,
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: AppColors.onBackground,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google girişi yakında eklenecek.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabın yok mu? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.goNamed(RouteNames.register),
                      child: Text(
                        'Kayıt Ol',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
