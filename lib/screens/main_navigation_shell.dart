import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/floating_pill_nav_bar.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'teachers_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  // Home is at index 2 (exact middle of 5 tabs)
  int _currentIndex = 2;
  final Map<String, Widget> _cachedScreens = {};

  static const List<NavDestinationItem> _allNavItems = [
    NavDestinationItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    NavDestinationItem(
      id: 'faculty',
      label: 'Faculty',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_alt_rounded,
    ),
    NavDestinationItem(
      id: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    NavDestinationItem(
      id: 'notifications',
      label: 'Notifs',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    NavDestinationItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  Widget _getScreen(String id) {
    return _cachedScreens.putIfAbsent(id, () {
      switch (id) {
        case 'attendance':
          return const AttendanceScreen(isTabMode: true);
        case 'faculty':
          return const TeachersScreen(isTabMode: true);
        case 'home':
          return DashboardScreen(key: DashboardScreen.dashboardKey, isTabMode: true);
        case 'notifications':
          return const NotificationsScreen();
        case 'settings':
          return const SettingsScreen(isTabMode: true);
        default:
          return DashboardScreen(key: DashboardScreen.dashboardKey, isTabMode: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _allNavItems.map((item) => _getScreen(item.id)).toList(),
        ),
        bottomNavigationBar: isKeyboardOpen
            ? null
            : Container(
                color: theme.colorScheme.surface,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: FloatingPillNavBar(
                      selectedIndex: _currentIndex,
                      items: _allNavItems,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
