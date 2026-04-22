import 'package:flutter/material.dart';

import '../../features/businesses/screens/business_dashboard_screen.dart';
import '../../features/businesses/screens/business_orders_screen.dart';
import '../../features/businesses/screens/business_profile_screen.dart';
import '../theme/app_colors.dart';

/// Business application scaffold with bottom navigation bar.
///
/// Similar to [MainScaffold] but with business-specific tabs:
/// Panel, Ürünlerim, Siparişler, Profil.
///
/// Per `UI_GUIDELINES.md`:
/// - Active tab: terracotta icon + label
/// - Inactive: gray
/// - White background with top border
class BusinessScaffold extends StatefulWidget {
  /// Creates the [BusinessScaffold].
  const BusinessScaffold({super.key});

  @override
  State<BusinessScaffold> createState() => _BusinessScaffoldState();
}

class _BusinessScaffoldState extends State<BusinessScaffold> {
  int _currentIndex = 0;

  /// The screens for each business tab.
  static const List<Widget> _screens = [
    BusinessDashboardScreen(),
    _BusinessProductsFullScreen(),
    BusinessOrdersScreen(),
    BusinessProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(
                  0,
                  Icons.grid_view_outlined,
                  Icons.grid_view,
                  'Panel',
                ),
                _buildNavItem(
                  1,
                  Icons.inventory_2_outlined,
                  Icons.inventory_2,
                  'Ürünlerim',
                ),
                _buildNavItem(
                  2,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Siparişler',
                ),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single bottom navigation item.
  Widget _buildNavItem(
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppColors.primary : AppColors.hintText;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen product list for the "Ürünlerim" tab.
///
/// Reuses the same data as the dashboard but shows all products.
class _BusinessProductsFullScreen extends StatelessWidget {
  const _BusinessProductsFullScreen();

  @override
  Widget build(BuildContext context) {
    // This delegates to the dashboard's product section as a full screen.
    // The BusinessDashboardScreen already shows products; this tab
    // shows the same list without the dashboard cards.
    return const BusinessDashboardScreen(productsOnly: true);
  }
}
