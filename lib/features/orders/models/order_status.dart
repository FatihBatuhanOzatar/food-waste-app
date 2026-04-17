/// Status of a reservation/order throughout its lifecycle.
///
/// Transitions: pending → confirmed → pickedUp
///              pending → cancelled
///              confirmed → cancelled
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
}
