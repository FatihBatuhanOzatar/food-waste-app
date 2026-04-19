import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable text input field matching the app's design system.
///
/// Wraps [TextFormField] with consistent styling per `UI_GUIDELINES.md`:
/// surface background, outline border, 52px height, 12px radius.
class AppTextField extends StatelessWidget {
  /// Creates an [AppTextField].
  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Label displayed above the field.
  final String? labelText;

  /// Hint text inside the field.
  final String? hintText;

  /// Icon displayed at the start of the field.
  final Widget? prefixIcon;

  /// Icon displayed at the end of the field.
  final Widget? suffixIcon;

  /// Whether to obscure input (for passwords).
  final bool obscureText;

  /// Validation function returning an error string or null.
  final String? Function(String?)? validator;

  /// Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Called when the user submits the field.
  final void Function(String)? onFieldSubmitted;

  /// Autofill hints for the field.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              labelText!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          autofillHints: autofillHints,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
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
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}
