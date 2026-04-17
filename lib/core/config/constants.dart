/// App-wide constants for the Food Waste App.
///
/// Values marked with `TODO` are pending team decisions and must NOT
/// be treated as final until the comment is resolved and this file is updated.
abstract final class AppConstants {
  // ---------------------------------------------------------------------------
  // Impact metrics
  // ---------------------------------------------------------------------------

  /// Average weight in kilograms of food saved per order.
  ///
  /// TODO: Pending team decision — proposed 0.8 kg/order (see PROJECT_CONTEXT.md).
  static const double averageFoodWeightKg = 0.8;

  /// Estimated kilograms of CO₂ emissions prevented per order.
  ///
  /// TODO: Pending team decision — proposed 2.5 kg CO₂/order (see PROJECT_CONTEXT.md).
  static const double co2PerOrderKg = 2.5;

  // ---------------------------------------------------------------------------
  // Business model
  // ---------------------------------------------------------------------------

  /// Commission rate applied per transaction in Phase 2 (post-MVP).
  ///
  /// TODO: Pending team decision — proposed range 10–15% (see PROJECT_CONTEXT.md).
  static const double commissionRate = 0.10;

  // ---------------------------------------------------------------------------
  // Dynamic pricing
  // ---------------------------------------------------------------------------

  /// Discount tiers for time-based dynamic pricing.
  ///
  /// Each entry maps hours-before-closing to a discount fraction.
  /// Example: an entry of `{3: 0.30}` means 3 hours before closing
  /// the price is discounted by 30% (multiply original price by 0.70).
  ///
  /// TODO: Pending team decision — proposed tiers 30%/50%/70% at 3h/2h/1h
  /// marks (see PROJECT_CONTEXT.md). Also pending decision on whether
  /// discounts are automatic or require a business override.
  static const Map<int, double> dynamicPricingTiers = {
    3: 0.30,
    2: 0.50,
    1: 0.70,
  };

  // ---------------------------------------------------------------------------
  // Map / discovery
  // ---------------------------------------------------------------------------

  /// Default search radius in kilometres for nearby business discovery.
  static const double defaultSearchRadiusKm = 2.0;

  /// Default Google Maps zoom level for the home map view.
  static const double defaultMapZoom = 15.0;

  // ---------------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------------

  /// Maximum number of items a user can include in a single reservation.
  static const int maxItemsPerReservation = 5;
}
