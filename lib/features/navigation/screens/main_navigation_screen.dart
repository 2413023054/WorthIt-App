import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../feasibility/screens/feasibility_screen.dart';
import '../../comparison/screens/comparison_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final LocalStorageService localStorage;
  final Function(ThemeMode)? onThemeModeChanged;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.localStorage,
    this.onThemeModeChanged,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      DashboardScreen(
        localStorage: widget.localStorage,
        onNavigateToTab: _onTabTapped,
      ),
      FeasibilityScreen(
        localStorage: widget.localStorage,
      ),
      ComparisonScreen(
        localStorage: widget.localStorage,
      ),
      HistoryScreen(
        localStorage: widget.localStorage,
      ),
      ProfileScreen(
        localStorage: widget.localStorage,
        onThemeModeChanged: widget.onThemeModeChanged ?? (_) {},
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: Colors.transparent,
          indicatorColor: (isDark
                  ? AppColors.secondaryCyan
                  : AppColors.primaryIndigo)
              .withOpacity(0.18),
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: isDark
                    ? AppColors.secondaryCyan
                    : AppColors.primaryIndigo,
              ),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: Icon(
                Icons.insights_rounded,
                color: isDark
                    ? AppColors.secondaryCyan
                    : AppColors.primaryIndigo,
              ),
              label: AppStrings.navFeasibility,
            ),
            NavigationDestination(
              icon: const Icon(Icons.compare_arrows_outlined),
              selectedIcon: Icon(
                Icons.compare_arrows_rounded,
                color: isDark
                    ? AppColors.secondaryCyan
                    : AppColors.primaryIndigo,
              ),
              label: AppStrings.navComparison,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: isDark
                    ? AppColors.secondaryCyan
                    : AppColors.primaryIndigo,
              ),
              label: AppStrings.navHistory,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: isDark
                    ? AppColors.secondaryCyan
                    : AppColors.primaryIndigo,
              ),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
