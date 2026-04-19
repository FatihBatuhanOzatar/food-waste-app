import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Primary full-width button matching the app's design system.
///
/// Per `UI_GUIDELINES.md`: full width, 52px height, terracotta background,
/// 12px radius, no shadow. Supports a loading state that shows a
/// [CircularProgressIndicator] in place of the label.
class AppButton extends StatelessWidget {
  /// Creates an [AppButton].
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.icon,
  });

  /// Button label text.
  final String label;

  /// Callback when the button is pressed. Ignored when [isLoading] or
  /// [isDisabled] is true.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  /// Whether to use outlined style instead of filled.
  final bool isOutlined;

  /// Whether the button is disabled (grayed out).
  final bool isDisabled;

  /// Optional leading icon widget.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outline),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          child: _buildChild(context),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.primary,
          foregroundColor: isDisabled
              ? AppColors.hintText
              : AppColors.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: _buildChild(context),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined ? AppColors.primary : AppColors.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isOutlined
                  ? AppColors.onBackground
                  : (isDisabled ? AppColors.hintText : AppColors.onPrimary),
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isOutlined
            ? AppColors.onBackground
            : (isDisabled ? AppColors.hintText : AppColors.onPrimary),
      ),
    );
  }
}
