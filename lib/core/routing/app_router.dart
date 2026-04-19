import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/kvkk_consent_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/businesses/providers/business_provider.dart';
import '../../features/businesses/screens/business_setup_screen.dart';
import '../../features/businesses/screens/product_create_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../widgets/business_scaffold.dart';
import '../widgets/main_scaffold.dart';
import 'route_names.dart';

/// Provides the [GoRouter] instance with auth-aware redirect logic.
///
/// The router watches [authStateProvider] and [currentUserProvider] to
/// determine where to redirect:
/// - Not authenticated → `/login`
/// - Authenticated but KVKK not accepted → `/kvkk-consent`
/// - Authenticated, KVKK accepted, role='user' → `/home`
/// - Authenticated, KVKK accepted, role='business':
///   - Has business record → `/business`
///   - No business record → `/business/setup`
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
      final isOnBusinessPage = currentPath.startsWith('/business');
      final isOnHomePage = currentPath == '/home';

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

      // Logged in and KVKK accepted → route based on role.
      if (user != null && user.hasAcceptedKvkk) {
        // On auth/kvkk/root pages → redirect to appropriate home.
        if (isOnAuthPage || isOnKvkkPage || currentPath == '/') {
          if (user.role == 'business') {
            return '/business';
          }
          return '/home';
        }

        // Prevent user-role from accessing business pages.
        if (user.role == 'user' && isOnBusinessPage) {
          return '/home';
        }

        // Prevent business-role from accessing user home.
        if (user.role == 'business' && isOnHomePage) {
          return '/business';
        }
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
      // Business routes
      GoRoute(
        path: '/business',
        name: RouteNames.businessDashboard,
        builder: (context, state) => const _BusinessRouteHandler(),
      ),
      GoRoute(
        path: '/business/setup',
        name: RouteNames.businessSetup,
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/business/products/new',
        name: RouteNames.productCreate,
        builder: (context, state) => const ProductCreateScreen(),
      ),
      GoRoute(
        path: '/business/products/:id/edit',
        name: RouteNames.productEdit,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductCreateScreen(productId: id);
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

/// Routes business users to either the dashboard or setup screen
/// based on whether they have a business record.
class _BusinessRouteHandler extends ConsumerWidget {
  const _BusinessRouteHandler();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(myBusinessProvider);

    return businessAsync.when(
      data: (business) {
        if (business == null) {
          // No business record → redirect to setup.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.goNamed(RouteNames.businessSetup);
            }
          });
          return const _LoadingScreen();
        }
        return const BusinessScaffold();
      },
      loading: () => const _LoadingScreen(),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F0EB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFB91C1C),
              ),
              const SizedBox(height: 16),
              Text(
                'İşletme bilgisi yüklenemedi.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(myBusinessProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
