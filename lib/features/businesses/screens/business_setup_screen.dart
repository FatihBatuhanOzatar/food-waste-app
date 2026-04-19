import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/business_provider.dart';

/// Business onboarding form screen.
///
/// Shown when a user with `role == 'business'` has accepted KVKK
/// but has not yet created a business profile.
class BusinessSetupScreen extends ConsumerStatefulWidget {
  /// Creates the [BusinessSetupScreen].
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'bakery';
  bool _isLoading = false;

  /// Category options with Turkish labels.
  static const Map<String, String> _categories = {
    'bakery': 'Fırın',
    'cafe': 'Kafe',
    'patisserie': 'Pastane',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // Title
                Text(
                  'İşletme Bilgilerini\nTamamla',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'İşletmenizi oluşturmak için aşağıdaki bilgileri doldurun.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Business name
                AppTextField(
                  controller: _nameController,
                  labelText: 'İşletme Adı',
                  hintText: 'Örn: Tarihi Simit Fırını',
                  prefixIcon: const Icon(
                    Icons.store,
                    color: AppColors.hintText,
                    size: 20,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İşletme adı gereklidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Description
                AppTextField(
                  controller: _descriptionController,
                  labelText: 'Açıklama',
                  hintText: 'İşletmeniz hakkında kısa bilgi',
                  prefixIcon: const Icon(
                    Icons.description,
                    color: AppColors.hintText,
                    size: 20,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Açıklama gereklidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Phone
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Telefon',
                  hintText: '05XX XXX XX XX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: AppColors.hintText,
                    size: 20,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Telefon numarası gereklidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Address
                AppTextField(
                  controller: _addressController,
                  labelText: 'Adres',
                  hintText: 'İşletme adresi',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.hintText,
                    size: 20,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Adres gereklidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Category dropdown
                _buildCategoryDropdown(),
                const SizedBox(height: AppSpacing.md),
                // Location info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Konum otomatik olarak belirlendi.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.hintText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Submit button
                AppButton(
                  label: 'İşletmemi Oluştur',
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the category dropdown.
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Kategori',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyLarge,
              items: _categories.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Validates and submits the business creation form.
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(businessNotifierProvider.notifier);
      await notifier.createBusiness(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        // TODO: Implement real geocoding/location picker.
        // Hardcoded to Istanbul University coordinates for now.
        latitude: 41.0115,
        longitude: 28.9644,
        category: _selectedCategory,
      );

      if (mounted) {
        context.goNamed(RouteNames.businessDashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.toUserMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
