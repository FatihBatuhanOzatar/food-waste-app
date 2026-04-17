import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// Application router configuration.
///
/// Currently wired to a single placeholder route while individual feature
/// screens are implemented sprint by sprint. Full routing — including
/// authentication guards, deep links, and nested navigation — will be added
/// when the `auth` and `home` features are implemented.
///
/// See [RouteNames] for the complete set of reserved route names.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.home,
      builder: (context, state) => const _PlaceholderScreen(),
    ),
  ],
);

/// Temporary placeholder screen rendered until feature screens are connected.
///
/// This widget will be removed as routes are wired to real feature screens.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text(
          'Food Waste App — yakında!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
