/// Status of a reservation/order throughout its lifecycle.
///
/// Transitions: pending → confirmed → pickedUp
///              pending → cancelled
///              confirmed → cancelled
///              pending → expired (time-based)
///
/// See ARCHITECTURE.md and FEATURE_SPECS.md for the full state machine.
enum OrderStatus {
  /// Reservation created by the user, awaiting business confirmation.
  pending,

  /// Order approved by the business owner.
  confirmed,

  /// Product collected by the user at the business location.
  pickedUp,

  /// Order cancelled by either the user or the business before pickup.
  cancelled,

  /// Order expired because pickup window passed without action.
  expired;

  /// Parses an [OrderStatus] from a database string value.
  ///
  /// Handles both Dart enum names (`pickedUp`) and database snake_case
  /// values (`picked_up`).
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value || e.dbValue == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Database-compatible snake_case string.
  String get dbValue {
    switch (this) {
      case OrderStatus.pickedUp:
        return 'picked_up';
      default:
        return name;
    }
  }

  /// Turkish display label for user-facing UI.
  String get displayLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Onay Bekleniyor';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.pickedUp:
        return 'Teslim Alındı';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
      case OrderStatus.expired:
        return 'Süresi Doldu';
    }
  }
}
