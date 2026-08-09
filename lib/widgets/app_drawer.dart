import 'package:flutter/material.dart';
import '../screens/attendance_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/teachers_screen.dart';
import '../services/etlab_api_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = EtlabApiService();
    final profile = api.profileData;

    String studentName = 'Student';
    String subdomainText = '${api.subdomain}.etlab.in';

    if (profile != null) {
      if (profile.containsKey('student') && profile['student'] is Map) {
        final st = profile['student'] as Map<String, dynamic>;
        studentName = (st['name'] ?? st['full_name'] ?? st['student_name'] ?? 'Student').toString();
      } else {
        studentName = (profile['name'] ?? profile['full_name'] ?? profile['student_name'] ?? 'Student').toString();
      }
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(
              studentName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            accountEmail: Text(
              subdomainText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: currentRoute == '/dashboard',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/dashboard') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Attendance'),
            selected: currentRoute == '/attendance',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/attendance') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Faculty'),
            selected: currentRoute == '/faculty',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/faculty') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TeachersScreen()),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            selected: currentRoute == '/settings',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await EtlabApiService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
