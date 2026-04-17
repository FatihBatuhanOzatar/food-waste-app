/// Route name constants used throughout the app.
///
/// Always reference these constants instead of raw strings to prevent
/// typos and make route refactoring safe across the codebase.
///
/// **Usage:**
/// ```dart
/// context.goNamed(RouteNames.productDetail, pathParameters: {'id': id});
/// ```
abstract final class RouteNames {
  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Login screen.
  static const String login = 'login';

  /// Registration screen.
  static const String register = 'register';

  /// KVKK (Turkish personal data law) consent screen.
  static const String kvkkConsent = 'kvkk-consent';

  // ---------------------------------------------------------------------------
  // Consumer
  // ---------------------------------------------------------------------------

  /// Home / product discovery screen.
  static const String home = 'home';

  /// Product detail page.
  static const String productDetail = 'product-detail';

  /// Reservation creation flow.
  static const String reservation = 'reservation';

  /// User's order history.
  static const String myOrders = 'my-orders';

  /// User profile and settings.
  static const String profile = 'profile';

  /// Environmental impact dashboard.
  static const String impactDashboard = 'impact-dashboard';

  // ---------------------------------------------------------------------------
  // Business
  // ---------------------------------------------------------------------------

  /// Business owner dashboard.
  static const String businessDashboard = 'business-dashboard';

  /// Product creation / editing form.
  static const String productCreate = 'product-create';

  /// Business-side order management.
  static const String businessOrders = 'business-orders';

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------

  /// Full-screen Google Maps view.
  static const String map = 'map';
}
