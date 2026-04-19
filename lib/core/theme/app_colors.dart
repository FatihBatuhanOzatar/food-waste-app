import 'package:flutter/material.dart';

/// Brand color palette for the Food Waste App.
///
/// The palette is intentionally terracotta-based to differentiate from
/// the green-dominated food waste app category.
///
/// **Rule:** Never use raw hex color literals in widget code.
/// Always reference these constants or `Theme.of(context).colorScheme`.
abstract final class AppColors {
  /// Primary brand color — terracotta.
  static const Color primary = Color(0xFFC1440E);

  /// Text/icon color on [primary] surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Warm beige application background.
  static const Color background = Color(0xFFF5F0EB);

  /// Surface color for cards, bottom sheets, and dialogs.
  static const Color surface = Color(0xFFFFFFFF);

  /// Text/icon color on [background].
  static const Color onBackground = Color(0xFF2C1A0E);

  /// Text/icon color on [surface].
  static const Color onSurface = Color(0xFF2C1A0E);

  /// Secondary accent — light terracotta.
  static const Color secondary = Color(0xFFE8A090);

  /// Text/icon color on [secondary] surfaces.
  static const Color onSecondary = Color(0xFF2C1A0E);

  /// Input field borders, dividers — warm gray.
  static const Color outline = Color(0xFFD6CFC4);

  /// Category chip unselected background, subtle contrast areas.
  static const Color surfaceVariant = Color(0xFFF0E8E0);

  /// Semantic green — reserved exclusively for impact metrics (kg saved, CO₂).
  ///
  /// Do NOT use this color for general decoration. Per brand guidelines
  /// terracotta is the primary accent everywhere else.
  static const Color semanticGreen = Color(0xFF059669);

  /// Semantic amber — countdown timers, urgency indicators.
  static const Color semanticAmber = Color(0xFFD97706);

  /// Semantic red — sold-out badges, order rejection.
  static const Color semanticRed = Color(0xFFDC2626);

  /// Error state color.
  static const Color error = Color(0xFFB91C1C);

  /// Text/icon color on [error] surfaces.
  static const Color onError = Color(0xFFFFFFFF);

  /// Subtle border/divider — 30 % opacity dark brown.
  ///
  /// Use for input field borders and list dividers.
  static const Color borderSubtle = Color(0x4D2C1A0E);

  /// Hint text color — medium gray.
  static const Color hintText = Color(0xFF9E9E9E);
}
