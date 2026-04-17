/// Spacing scale constants for consistent layout throughout the app.
///
/// Always use these constants instead of magic numbers.
///
/// **Example:**
/// ```dart
/// SizedBox(height: AppSpacing.md)
/// Padding(padding: EdgeInsets.all(AppSpacing.sm))
/// ```
abstract final class AppSpacing {
  /// Extra-small spacing — 4 dp.
  static const double xs = 4;

  /// Small spacing — 8 dp.
  static const double sm = 8;

  /// Medium spacing — 16 dp (default padding unit).
  static const double md = 16;

  /// Large spacing — 24 dp.
  static const double lg = 24;

  /// Extra-large spacing — 32 dp.
  static const double xl = 32;

  /// Double extra-large spacing — 48 dp.
  static const double xxl = 48;
}
