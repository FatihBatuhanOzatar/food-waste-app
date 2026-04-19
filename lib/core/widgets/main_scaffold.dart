import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/orders/screens/my_orders_screen.dart';
import '../../features/products/screens/product_list_screen.dart';

/// Main application scaffold with bottom navigation bar.
///
/// Wraps the home screen and future tab screens. Follows the
/// Bottom Navigation Bar spec from `docs/UI_GUIDELINES.md`:
/// - 4 tabs: Keşfet, Siparişlerim, Etkim, Profil
/// - Active tab: terracotta icon + label
/// - Inactive: gray
/// - White background with top border
class MainScaffold extends StatefulWidget {
  /// Creates the [MainScaffold].
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  /// The screens for each tab.
  ///
  /// Only the first tab (Keşfet) is implemented.
  /// Others are placeholder screens.
  static const List<Widget> _screens = [
    ProductListScreen(),
    MyOrdersScreen(),
    _PlaceholderScreen(title: 'Etkim', message: 'Yakında'),
    _PlaceholderScreen(title: 'Profil', message: 'Yakında'),
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
                  Icons.explore_outlined,
                  Icons.explore,
                  'Keşfet',
                ),
                _buildNavItem(
                  1,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Siparişlerim',
                ),
                _buildNavItem(2, Icons.eco_outlined, Icons.eco, 'Etkim'),
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

/// Placeholder screen for unimplemented tabs.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: AppColors.hintText.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.hintText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
