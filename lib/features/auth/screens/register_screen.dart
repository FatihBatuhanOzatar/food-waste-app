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

/// Registration screen matching `docs/designs/register.png`.
///
/// Includes a segmented control for user/business toggle, form fields
/// for personal info, and conditional business fields. Validates all
/// inputs before calling [AuthNotifier.register].
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates the [RegisterScreen].
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Business-specific controllers
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isBusiness = false;
  bool _termsAccepted = false;
  String _selectedCategory = 'bakery';

  /// Business category options with Turkish labels.
  static const Map<String, String> _categoryOptions = {
    'bakery': 'Fırın',
    'cafe': 'Kafe',
    'patisserie': 'Pastane',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanım koşullarını kabul etmelisiniz.'),
        ),
      );
      return;
    }

    final role = _isBusiness ? 'business' : 'user';

    // NOTE: Business-specific fields (name, category, address) are collected
    // here but the `businesses` table row is NOT created during registration.
    // That step happens post-KVKK. For now, we just pass role: 'business'.

    await ref
        .read(authNotifierProvider.notifier)
        .register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back arrow and title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.onBackground,
                    ),
                    onPressed: () => context.goNamed(RouteNames.login),
                  ),
                  Expanded(
                    child: Text(
                      'Hesap Oluştur',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Spacer for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Segmented control: Kullanıcı / İşletme
                      _buildSegmentedControl(),
                      const SizedBox(height: AppSpacing.lg),

                      // Ad Soyad
                      AppTextField(
                        controller: _nameController,
                        labelText: 'Ad Soyad',
                        hintText: 'Örn: Ayşe Yılmaz',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.hintText,
                          size: 20,
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ad soyad boş bırakılamaz.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // E-posta
                      AppTextField(
                        controller: _emailController,
                        labelText: 'E-posta',
                        hintText: 'ornek@posta.com',
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: AppColors.hintText,
                          size: 20,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: EmailValidator.validate,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Şifre
                      AppTextField(
                        controller: _passwordController,
                        labelText: 'Şifre',
                        hintText: '••••••••',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.hintText,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.hintText,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
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
                      const SizedBox(height: AppSpacing.md),

                      // Şifre Tekrar
                      AppTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Şifre Tekrar',
                        hintText: '••••••••',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: AppColors.hintText,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.hintText,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre tekrar boş bırakılamaz.';
                          }
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Telefon (optional)
                      AppTextField(
                        controller: _phoneController,
                        labelText: 'Telefon (İsteğe bağlı)',
                        hintText: '+90 5XX XXX XX XX',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.hintText,
                          size: 20,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),

                      // Business-specific fields
                      if (_isBusiness) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _businessNameController,
                          labelText: 'İşletme Adı',
                          hintText: 'Örn: Kampüs Fırını',
                          prefixIcon: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.hintText,
                            size: 20,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (_isBusiness &&
                                (value == null || value.trim().isEmpty)) {
                              return 'İşletme adı boş bırakılamaz.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Kategori dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                'Kategori',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outline),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.hintText,
                                  ),
                                  items: _categoryOptions.entries
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Adres
                        AppTextField(
                          controller: _addressController,
                          labelText: 'Adres',
                          hintText: 'İşletme adresi',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.hintText,
                            size: 20,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (_isBusiness &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Adres boş bırakılamaz.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Terms checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _termsAccepted = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: AppColors.outline,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _termsAccepted = !_termsAccepted;
                                });
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: const [
                                    TextSpan(
                                      text: 'Kullanım Koşulları',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: '\'nı ve '),
                                    TextSpan(
                                      text: 'Gizlilik Politikası',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '\'nı okudum, kabul ediyorum.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Error display
                      if (authState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            ErrorHandler.toUserMessage(authState.error!),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Register button
                      AppButton(
                        label: 'Kayıt Ol',
                        onPressed: _handleRegister,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Zaten hesabın var mı? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.goNamed(RouteNames.login),
                            child: Text(
                              'Giriş Yap',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  /// Builds the Kullanıcı / İşletme segmented control toggle.
  Widget _buildSegmentedControl() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBusiness = false),
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _isBusiness ? Colors.transparent : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Kullanıcı',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _isBusiness
                        ? AppColors.onBackground
                        : AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBusiness = true),
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _isBusiness ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'İşletme',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _isBusiness
                        ? AppColors.onPrimary
                        : AppColors.onBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
