import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// KVKK (Turkish personal data law) consent screen matching
/// `docs/designs/kvkk_consent.png`.
///
/// Displays the privacy notice text, two required checkboxes, and a
/// "Devam Et" button that is disabled until both checkboxes are checked.
///
/// This screen is NOT dismissible — KVKK compliance is a legal requirement.
class KvkkConsentScreen extends ConsumerStatefulWidget {
  /// Creates the [KvkkConsentScreen].
  const KvkkConsentScreen({super.key});

  @override
  ConsumerState<KvkkConsentScreen> createState() => _KvkkConsentScreenState();
}

class _KvkkConsentScreenState extends ConsumerState<KvkkConsentScreen> {
  bool _readAndUnderstood = false;
  bool _consentGiven = false;

  bool get _canProceed => _readAndUnderstood && _consentGiven;

  Future<void> _handleAccept() async {
    if (!_canProceed) return;
    await ref.read(authNotifierProvider.notifier).acceptKvkk();
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
                    onPressed: () async {
                      // Sign out and go back to login — user cannot skip KVKK
                      await ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Privacy & Trust',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // Title
                    Text(
                      'Kişisel Verilerin\nKorunması',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    Text(
                      'Deneyiminizi kişiselleştirmek ve güvenliğinizi '
                      'sağlamak için izinlerinize ihtiyacımız var.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.hintText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Privacy notice card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aydınlatma Metni',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // TODO: Replace with real legal text when
                            // available from the legal team.
                            Text(
                              'Kişisel verileriniz, veri sorumlusu sıfatıyla '
                              'şirketimiz tarafından 6698 sayılı Kişisel '
                              'Verilerin Korunması Kanunu ("Kanun") uyarınca '
                              'aşağıda açıklanan kapsamda işlenebilecektir. '
                              'Hizmetlerimizi sunabilmek, iyileştirebilmek '
                              've yasal yükümlülüklerimizi yerine '
                              'getirebilmek amacıyla belirli verilerinizi '
                              'topluyoruz.\n\n'
                              'Toplanan kişisel verileriniz; ürün ve '
                              'hizmetlerimizin sunulması, sipariş '
                              'süreçlerinin yönetimi, kullanıcı deneyiminin '
                              'iyileştirilmesi, yasal yükümlülüklerin '
                              'yerine getirilmesi ve istatistiksel '
                              'analizlerin yapılması amacıyla '
                              'işlenmektedir.\n\n'
                              'Kişisel verileriniz, yukarıda belirtilen '
                              'amaçlarla sınırlı olarak iş ortaklarımıza, '
                              'tedarikçilerimize ve yasal düzenlemeler '
                              'çerçevesinde yetkili kurum ve kuruluşlara '
                              'aktarılabilecektir.\n\n'
                              'Kanun\'un 11. maddesi gereğince; kişisel '
                              'verilerinizin işlenip işlenmediğini öğrenme, '
                              'işlenmişse buna ilişkin bilgi talep etme, '
                              'işlenme amacını ve bunların amacına uygun '
                              'kullanılıp kullanılmadığını öğrenme, '
                              'düzeltilmesini veya silinmesini isteme '
                              'haklarına sahipsiniz.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Checkbox 1: read and understood
                    _buildCheckboxRow(
                      value: _readAndUnderstood,
                      onChanged: (value) {
                        setState(() {
                          _readAndUnderstood = value ?? false;
                        });
                      },
                      label: 'Aydınlatma metnini okudum ve anladım.',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Checkbox 2: explicit consent
                    _buildCheckboxRow(
                      value: _consentGiven,
                      onChanged: (value) {
                        setState(() {
                          _consentGiven = value ?? false;
                        });
                      },
                      label:
                          'Kişisel verilerimin işlenmesine ve belirtilen '
                          'amaçlarla aktarılmasına açık rıza veriyorum.',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.xl),

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

                    // Devam Et button
                    AppButton(
                      label: 'Devam Et',
                      onPressed: _canProceed ? _handleAccept : null,
                      isLoading: isLoading,
                      isDisabled: !_canProceed,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Helper text
                    if (!_canProceed)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.hintText,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Devam etmek için lütfen yukarıdaki '
                            'onayları tamamlayın',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.hintText),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a checkbox row with label text and "Zorunlu alan" indicator.
  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '* Zorunlu alan',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
