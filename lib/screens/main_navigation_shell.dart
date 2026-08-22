import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/floating_pill_nav_bar.dart';
import '../widgets/navigation_tutorial.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'teachers_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}
class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  // Notifications lives in the top bar of each page, not in the dock.
  // Attendance sits right next to Home.
  int _currentIndex = 1;
  final Map<String, Widget> _cachedScreens = {};

  late final AnimationController _swapC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1.0,
  );
  late final CurvedAnimation _swapFade =
      CurvedAnimation(parent: _swapC, curve: Curves.easeOut);
  late final Animation<Offset> _swapSlide = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(_swapFade);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NavigationTutorial.maybeShow(context);
    });
  }

  @override
  void dispose() {
    _swapC.dispose();
    _swapFade.dispose();
    super.dispose();
  }

  static const List<NavDestinationItem> _allNavItems = [
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
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
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
          return const AttendanceScreen();
        case 'faculty':
          return const TeachersScreen();
        case 'home':
          return const DashboardScreen();
        case 'settings':
          return const SettingsScreen();
        default:
          return const DashboardScreen();
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
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            for (var i = 0; i < _allNavItems.length; i++)
              Offstage(
                offstage: i != _currentIndex,
                child: TickerMode(
                  enabled: i == _currentIndex,
                  child: i == _currentIndex
                      ? FadeTransition(
                          opacity: _swapFade,
                          child: SlideTransition(
                            position: _swapSlide,
                            child: _getScreen(_allNavItems[i].id),
                          ),
                        )
                      : _getScreen(_allNavItems[i].id),
                ),
              ),
          ],
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
                      key: NavigationTutorial.navBarKey,
                      selectedIndex: _currentIndex,
                      items: _allNavItems,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _swapC.forward(from: 0);
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
