import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/etlab_api_service.dart';
import 'attendance_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'teachers_screen.dart';

class HubScreen extends StatefulWidget {
  final bool isTabMode;
  final VoidCallback? onNavConfigChanged;
  final Function(int)? onSwitchTab;

  static const String navPrefsKey = 'user_nav_middle_tabs';
  static const List<String> allMiddleTabs = [
    'attendance',
    'faculty',
    'notifications',
    'settings',
  ];

  static final Map<String, ({String label, IconData icon, IconData selectedIcon})> tabMetadata = {
    'attendance': (
      label: 'Attendance',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    'faculty': (
      label: 'Faculty',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_alt_rounded,
    ),
    'notifications': (
      label: 'Notifs',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    'settings': (
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  };

  const HubScreen({
    super.key,
    this.isTabMode = false,
    this.onNavConfigChanged,
    this.onSwitchTab,
  });

  static Future<void> openNavCustomizer(BuildContext context, {VoidCallback? onSaved}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentMiddleTabs = List<String>.from(prefs.getStringList(HubScreen.navPrefsKey) ?? ['attendance', 'faculty']);
    currentMiddleTabs.retainWhere((id) => HubScreen.tabMetadata.containsKey(id));
    if (currentMiddleTabs.isEmpty) currentMiddleTabs = ['attendance', 'faculty'];

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customize Bottom Bar',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can only select up to 2 extras. Home is always 1st, and More is always last.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Locked Home Indicator
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.home_rounded, color: theme.colorScheme.primary),
                        title: const Text('Home / Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Locked — Always 1st'),
                        trailing: const Icon(Icons.lock_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Middle Tabs Selection
                    ...HubScreen.allMiddleTabs.map((tabId) {
                      final meta = HubScreen.tabMetadata[tabId];
                      if (meta == null) return const SizedBox.shrink();
                      final isSelected = currentMiddleTabs.contains(tabId);

                      return CheckboxListTile(
                        value: isSelected,
                        secondary: Icon(meta.icon),
                        title: Text(meta.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: isSelected
                            ? Text('Selected (${currentMiddleTabs.indexOf(tabId) + 1}/2)', style: TextStyle(color: theme.colorScheme.primary))
                            : const Text('Not on bar'),
                        onChanged: (bool? val) {
                          setModalState(() {
                            if (val == true) {
                              if (currentMiddleTabs.length < 2) {
                                currentMiddleTabs.add(tabId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You can only select up to 2 extras.'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (currentMiddleTabs.length > 1) {
                                currentMiddleTabs.remove(tabId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You must keep at least 1 extra tab selected.'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          });
                        },
                      );
                    }),

                    const SizedBox(height: 8),
                    // Locked More Indicator
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.widgets_rounded, color: theme.colorScheme.primary),
                        title: const Text('More & Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Locked — Always last'),
                        trailing: const Icon(Icons.lock_outline, size: 20),
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await prefs.setStringList(HubScreen.navPrefsKey, currentMiddleTabs);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          onSaved?.call();
                        },
                        child: const Text('Save Bottom Bar Layout'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  List<String> _pinnedMiddleTabs = ['attendance', 'faculty'];

  @override
  void initState() {
    super.initState();
    _loadPinned();
  }

  Future<void> _loadPinned() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(HubScreen.navPrefsKey);
    if (list != null && mounted) {
      final valid = List<String>.from(list)..retainWhere((id) => HubScreen.tabMetadata.containsKey(id));
      setState(() {
        _pinnedMiddleTabs = valid.isNotEmpty ? valid : ['attendance', 'faculty'];
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to log out of your academic session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await EtlabApiService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    bool isPinned = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isPinned
              ? theme.colorScheme.primary.withAlpha(120)
              : theme.colorScheme.outlineVariant.withAlpha(90),
          width: isPinned ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  if (isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin_rounded, size: 10, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 3),
                          Text(
                            'ON BAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub & Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Section Header
                Text(
                  'ALL FEATURES & TOOLS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),

                // Modern 2-Column Grid of Tiles
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildHubTile(
                      context,
                      title: 'Attendance',
                      subtitle: 'Subject logs & bunk predictor',
                      icon: Icons.analytics_rounded,
                      iconColor: theme.colorScheme.primary,
                      iconBgColor: theme.colorScheme.primaryContainer,
                      isPinned: _pinnedMiddleTabs.contains('attendance'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                        );
                      },
                    ),
                    _buildHubTile(
                      context,
                      title: 'Faculty',
                      subtitle: 'Advisor, HOD & teachers',
                      icon: Icons.people_alt_rounded,
                      iconColor: theme.colorScheme.secondary,
                      iconBgColor: theme.colorScheme.secondaryContainer,
                      isPinned: _pinnedMiddleTabs.contains('faculty'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeachersScreen()),
                        );
                      },
                    ),
                    _buildHubTile(
                      context,
                      title: 'Notifications',
                      subtitle: 'Absence alerts & tracker',
                      icon: Icons.notifications_rounded,
                      iconColor: theme.colorScheme.error,
                      iconBgColor: theme.colorScheme.errorContainer,
                      isPinned: _pinnedMiddleTabs.contains('notifications'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    _buildHubTile(
                      context,
                      title: 'Settings',
                      subtitle: 'Themes, target %, nav bar',
                      icon: Icons.settings_rounded,
                      iconColor: theme.colorScheme.tertiary,
                      iconBgColor: theme.colorScheme.tertiaryContainer,
                      isPinned: _pinnedMiddleTabs.contains('settings'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                        _loadPinned();
                        widget.onNavConfigChanged?.call();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showLogoutDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
