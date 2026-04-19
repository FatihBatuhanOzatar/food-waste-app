import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_list_provider.dart';
import '../providers/business_provider.dart';

/// Product creation and editing form screen.
///
/// In create mode (default): shows an empty form to add a new product.
/// In edit mode (when [productId] is provided): pre-fills with existing data.
class ProductCreateScreen extends ConsumerStatefulWidget {
  /// Creates the [ProductCreateScreen].
  ///
  /// Pass [productId] to enter edit mode with pre-filled data.
  const ProductCreateScreen({super.key, this.productId});

  /// If non-null, the screen is in edit mode for this product.
  final String? productId;

  @override
  ConsumerState<ProductCreateScreen> createState() =>
      _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _currentPriceController;
  late final TextEditingController _stockController;

  String _selectedCategory = 'bread';
  String _selectedListingType = 'menu_item';
  TimeOfDay _pickupStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _pickupEnd = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditMode => widget.productId != null;

  /// Category options with Turkish labels.
  static const Map<String, String> _categories = {
    'bread': 'Ekmek',
    'pastry': 'Börek/Poğaça',
    'sandwich': 'Sandviç',
    'dessert': 'Tatlı',
    'drink': 'İçecek',
    'mixed_box': 'Karışık Kutu',
    'other': 'Diğer',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _originalPriceController = TextEditingController();
    _currentPriceController = TextEditingController();
    _stockController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _currentPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Pre-fills form fields when in edit mode.
  void _prefillForEdit(Product product) {
    if (_isInitialized) return;
    _isInitialized = true;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _originalPriceController.text = product.originalPrice.toStringAsFixed(2);
    _currentPriceController.text = product.currentPrice.toStringAsFixed(2);
    _stockController.text = product.stock.toString();
    _selectedCategory = product.category;
    _selectedListingType = product.listingType;
    _pickupStart = TimeOfDay(
      hour: product.pickupStart.toLocal().hour,
      minute: product.pickupStart.toLocal().minute,
    );
    _pickupEnd = TimeOfDay(
      hour: product.pickupEnd.toLocal().hour,
      minute: product.pickupEnd.toLocal().minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    // In edit mode, watch the product to pre-fill fields.
    if (_isEditMode) {
      final businessAsync = ref.watch(myBusinessProvider);
      final business = businessAsync.valueOrNull;
      if (business != null) {
        final productsAsync = ref.watch(businessProductsProvider(business.id));
        productsAsync.whenData((products) {
          final product = products
              .where((p) => p.id == widget.productId)
              .firstOrNull;
          if (product != null) _prefillForEdit(product);
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Photo upload placeholder
                _PhotoUploadPlaceholder(),
                const SizedBox(height: AppSpacing.md),
                // Product name
                AppTextField(
                  controller: _nameController,
                  labelText: 'Ürün Adı',
                  hintText: 'Örn: Susamlı Simit Paketi',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ürün adı gereklidir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Description
                _buildMultilineField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hint: 'Ürün hakkında kısa açıklama (isteğe bağlı)',
                ),
                const SizedBox(height: AppSpacing.md),
                // Category dropdown
                _buildDropdown(
                  label: 'Kategori',
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Listing type toggle
                _buildListingTypeToggle(),
                const SizedBox(height: AppSpacing.md),
                // Price fields
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _originalPriceController,
                        labelText: 'Orijinal Fiyat (₺)',
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Gerekli';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Geçersiz fiyat';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _currentPriceController,
                        labelText: 'İndirimli Fiyat (₺)',
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Gerekli';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Geçersiz fiyat';
                          }
                          final original = double.tryParse(
                            _originalPriceController.text,
                          );
                          if (original != null && price >= original) {
                            return 'Orijinalden düşük olmalı';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Stock count
                AppTextField(
                  controller: _stockController,
                  labelText: 'Stok Adedi',
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Stok adedi gereklidir.';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock < 1) {
                      return 'En az 1 olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Pickup time pickers
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Gel-al Başlangıç',
                        time: _pickupStart,
                        onTap: () => _selectTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Gel-al Bitiş',
                        time: _pickupEnd,
                        onTap: () => _selectTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Submit button
                AppButton(
                  label: _isEditMode ? 'Güncelle' : 'Ürünü Yayınla',
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

  /// Builds a multiline text field for description.
  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        TextFormField(
          controller: controller,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  /// Builds a dropdown field.
  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
              value: value,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyLarge,
              items: items.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the listing type toggle (Menu Item / Surprise Box).
  Widget _buildListingTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Listeleme Tipi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildToggleSegment(
                label: 'Menü Ürünü',
                isSelected: _selectedListingType == 'menu_item',
                onTap: () => setState(() => _selectedListingType = 'menu_item'),
              ),
              _buildToggleSegment(
                label: 'Sürpriz Kutu',
                isSelected: _selectedListingType == 'surprise_box',
                onTap: () =>
                    setState(() => _selectedListingType = 'surprise_box'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a single segment of the toggle.
  Widget _buildToggleSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.onBackground,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a time picker field.
  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.hintText,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Opens a time picker dialog.
  Future<void> _selectTime({required bool isStart}) async {
    final initial = isStart ? _pickupStart : _pickupEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _pickupStart = picked;
        } else {
          _pickupEnd = picked;
        }
      });
    }
  }

  /// Validates and submits the form.
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validate pickup end is after start.
    final startMinutes = _pickupStart.hour * 60 + _pickupStart.minute;
    final endMinutes = _pickupEnd.hour * 60 + _pickupEnd.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gel-al bitiş saati, başlangıçtan sonra olmalıdır.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final business = await ref.read(myBusinessProvider.future);

      if (business == null) {
        throw Exception('İşletme bulunamadı.');
      }

      final now = DateTime.now();
      final pickupStart = DateTime(
        now.year,
        now.month,
        now.day,
        _pickupStart.hour,
        _pickupStart.minute,
      );
      final pickupEnd = DateTime(
        now.year,
        now.month,
        now.day,
        _pickupEnd.hour,
        _pickupEnd.minute,
      );

      if (_isEditMode) {
        await repo.updateProduct(widget.productId!, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          'category': _selectedCategory,
          'listing_type': _selectedListingType,
          'original_price': double.parse(_originalPriceController.text),
          'current_price': double.parse(_currentPriceController.text),
          'stock': int.parse(_stockController.text),
          'pickup_start': pickupStart.toUtc().toIso8601String(),
          'pickup_end': pickupEnd.toUtc().toIso8601String(),
        });
      } else {
        await repo.createProduct(
          businessId: business.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          category: _selectedCategory,
          listingType: _selectedListingType,
          originalPrice: double.parse(_originalPriceController.text),
          currentPrice: double.parse(_currentPriceController.text),
          stock: int.parse(_stockController.text),
          pickupStart: pickupStart,
          pickupEnd: pickupEnd,
        );
      }

      // Refresh product lists.
      ref.invalidate(businessProductsProvider(business.id));
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Ürün güncellendi.' : 'Ürün başarıyla eklendi.',
            ),
          ),
        );
        context.pop();
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

/// Photo upload placeholder with camera icon.
///
/// TODO: Implement real photo upload when storage is ready.
class _PhotoUploadPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf yükleme yakında eklenecek.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: AppColors.hintText.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ürün Fotoğrafı Ekle',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.hintText),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '(Yakında)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.hintText.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
