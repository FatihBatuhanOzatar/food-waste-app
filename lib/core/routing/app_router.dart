import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/kvkk_consent_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../widgets/main_scaffold.dart';
import 'route_names.dart';

/// Provides the [GoRouter] instance with auth-aware redirect logic.
///
/// The router watches [authStateProvider] and [currentUserProvider] to
/// determine where to redirect:
/// - Not authenticated → `/login`
/// - Authenticated but KVKK not accepted → `/kvkk-consent`
/// - Authenticated and KVKK accepted → `/home`
final appRouterProvider = Provider<GoRouter>((ref) {
  // Use a listenable to trigger router refresh on auth state changes.
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      // While auth state is loading, don't redirect.
      final isAuthLoading = authState.isLoading || currentUser.isLoading;
      if (isAuthLoading) return null;

      // Determine auth status from both the auth stream and the profile.
      final isLoggedIn =
          authState.valueOrNull != null &&
          authState.valueOrNull!.session != null;
      final user = currentUser.valueOrNull;

      final currentPath = state.matchedLocation;
      final isOnAuthPage =
          currentPath == '/login' || currentPath == '/register';
      final isOnKvkkPage = currentPath == '/kvkk-consent';

      // Not logged in → go to login (unless already on auth page).
      if (!isLoggedIn) {
        if (isOnAuthPage) return null;
        return '/login';
      }

      // Logged in but no profile yet (still loading) → stay put.
      if (user == null && !currentUser.hasError) return null;

      // Logged in but KVKK not accepted → go to KVKK consent.
      if (user != null && !user.hasAcceptedKvkk) {
        if (isOnKvkkPage) return null;
        return '/kvkk-consent';
      }

      // Logged in and KVKK accepted → go to home (unless already there).
      if (isOnAuthPage || isOnKvkkPage || currentPath == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/kvkk-consent',
        name: RouteNames.kvkkConsent,
        builder: (context, state) => const KvkkConsentScreen(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
    ],
  );
});

/// Listenable that triggers [GoRouter.refresh] when auth state changes.
///
/// Watches both [authStateProvider] and [currentUserProvider] so the
/// router re-evaluates its redirect logic whenever the user logs in,
/// logs out, or accepts KVKK.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

/// Simple loading screen shown at the root path while auth state resolves.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
