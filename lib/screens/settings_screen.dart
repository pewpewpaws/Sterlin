import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_logger_service.dart';
import '../services/etlab_api_service.dart';
import '../services/home_widget_service.dart';
import '../services/notifications_service.dart';
import '../services/safeword_service.dart';
import '../services/theme_service.dart';
import '../models/dashboard_data.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/navigation_tutorial.dart';
import '../widgets/page_header.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  bool? _notificationsEnabled;
  bool _isSyncing = false;
  Map<String, dynamic>? _backgroundStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationSettings();
    _loadBackgroundStatus();
    AppLoggerService().loadLogs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationSettings();
      _loadBackgroundStatus();
    }
  }

  Future<void> _loadNotificationSettings() async {
    final systemGranted =
        await NotificationsService().isSystemNotificationPermissionGranted();
    final inAppEnabled =
        await NotificationsService().areNotificationsEnabledInPrefs();
    if (mounted) {
      setState(() {
        _notificationsEnabled = systemGranted && inAppEnabled;
      });
    }
  }

  Future<void> _loadBackgroundStatus() async {
    try {
      const platform = MethodChannel('com.pewpewpaws.sterlin/battery');
      final res = await platform.invokeMapMethod<String, dynamic>(
        'getBackgroundStatus',
      );
      if (mounted) {
        setState(() {
          _backgroundStatus = res;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _applyThemeMode(ThemeMode mode) {
    if (mode == ThemeService().themeMode) return;
    ThemeService().setThemeMode(mode);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            Icons.logout_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out? You will need to enter your credentials to log back in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await EtlabApiService().logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  void _openSafeWordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Dev Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: SafeWordService.unlocked,
                builder: (context, unlocked, _) => Text(
                  unlocked
                      ? 'Extra details are currently visible.'
                      : 'Extra details are currently hidden.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    _confirmSafeWord(dialogContext, controller),
                decoration: const InputDecoration(
                  hintText: 'Access code',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            if (SafeWordService.unlocked.value)
              TextButton(
                onPressed: () {
                  SafeWordService.set(false);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Extra details hidden.'),
                      duration: const Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Hide'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _confirmSafeWord(dialogContext, controller),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSafeWord(
    BuildContext dialogContext,
    TextEditingController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = SafeWordService.matches(controller.text);
    await SafeWordService.set(ok);
    if (dialogContext.mounted) Navigator.pop(dialogContext);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Extra details unlocked.' : 'Extra details hidden.',
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyAllLogs(List<LogEntry> logs) {
    if (logs.isEmpty) return;
    final buffer = StringBuffer();
    for (var l in logs) {
      buffer.writeln('[${l.formatTimestamp()}] [${l.category}] ${l.message}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${logs.length} log entries copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBackgroundSyncDialog() {
    final status = _backgroundStatus?['status'] as String? ?? 'optimized';
    final isRestricted =
        _backgroundStatus?['isBackgroundRestricted'] as bool? ?? false;
    final isXiaomi = _backgroundStatus?['isXiaomi'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final curStatus = _backgroundStatus?['status'] as String? ?? status;
            final isUnrestricted = curStatus == 'unrestricted';

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.onSurfaceVariant.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUnrestricted
                                ? (isDark
                                    ? const Color(0xFF14532D)
                                    : const Color(0xFFDCFCE7))
                                : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isUnrestricted
                                ? Icons.check_circle_outline
                                : Icons.battery_charging_full_rounded,
                            color: isUnrestricted
                                ? (isDark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF15803D))
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background Activity & Sync',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isUnrestricted
                                    ? 'Running smoothly without limits'
                                    : 'May be throttled by battery saver',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status Summary Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnrestricted
                            ? (isDark
                                ? const Color(0xFF14532D).withAlpha(120)
                                : const Color(0xFFDCFCE7))
                            : (isRestricted
                                ? (isDark
                                    ? const Color(0xFF7F1D1D).withAlpha(120)
                                    : const Color(0xFFFEE2E2))
                                : theme.colorScheme.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnrestricted
                              ? (isDark
                                  ? const Color(0xFF4ADE80).withAlpha(120)
                                  : const Color(0xFF86EFAC))
                              : (isRestricted
                                  ? (isDark
                                      ? const Color(0xFFF87171).withAlpha(120)
                                      : const Color(0xFFFCA5A5))
                                  : theme.colorScheme.outlineVariant
                                      .withAlpha(80)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isUnrestricted
                                ? Icons.verified_rounded
                                : (isRestricted
                                    ? Icons.error_outline_rounded
                                    : Icons.info_outline_rounded),
                            size: 20,
                            color: isUnrestricted
                                ? (isDark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF15803D))
                                : (isRestricted
                                    ? (isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFDC2626))
                                    : theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUnrestricted
                                      ? 'Activity Status: Unrestricted'
                                      : (isRestricted
                                          ? 'Activity Status: Restricted'
                                          : 'Activity Status: Optimized (Standard)'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isUnrestricted
                                        ? (isDark
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFF15803D))
                                        : (isRestricted
                                            ? (isDark
                                                ? const Color(0xFFF87171)
                                                : const Color(0xFFDC2626))
                                            : theme.colorScheme.onSurface),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnrestricted
                                      ? 'Sterlin is exempt from battery saver restrictions. Widgets and absence notifications update on time.'
                                      : (isRestricted
                                          ? 'Android is blocking background tasks for this app. You must set Battery to "Unrestricted" or "Optimized" in App Settings.'
                                          : 'Android may throttle periodic background sync when your phone is asleep. Setting battery to "Unrestricted" ensures immediate widget updates.'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    if (!isUnrestricted) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.bolt),
                          label: const Text('Request Unrestricted Mode'),
                          onPressed: () async {
                            const platform = MethodChannel(
                              'com.pewpewpaws.sterlin/battery',
                            );
                            await platform.invokeMethod(
                              'requestIgnoreBatteryOptimizations',
                            );
                            await _loadBackgroundStatus();
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Open App Battery Settings'),
                        onPressed: () async {
                          const platform = MethodChannel(
                            'com.pewpewpaws.sterlin/battery',
                          );
                          await platform.invokeMethod('openAppBatterySettings');
                        },
                      ),
                    ),

                    if (isXiaomi) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text(
                            'Xiaomi / HyperOS Autostart Settings',
                          ),
                          onPressed: () async {
                            const platform = MethodChannel(
                              'com.pewpewpaws.sterlin/battery',
                            );
                            await platform.invokeMethod('openAutoStartSettings');
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundStatusBadge(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final status = _backgroundStatus?['status'] as String? ?? 'optimized';

    if (status == 'unrestricted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 13,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
            ),
            const SizedBox(width: 4),
            Text(
              'Unrestricted',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF15803D),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'restricted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 13,
              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 4),
            Text(
              'Restricted',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFF87171)
                    : const Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 13,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Optimized',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'API':
        return Colors.blue;
      case 'BG_TASK':
        return Colors.teal;
      case 'WIDGET':
        return Colors.indigo;
      case 'NOTIF':
        return Colors.purple;
      case 'ERROR':
        return theme.colorScheme.error;
      case 'CACHE':
        return Colors.orange;
      case 'SYSTEM':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }

  void _showAddCustomLogDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'DEBUG';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Debug Log Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'DEBUG', child: Text('DEBUG')),
                      DropdownMenuItem(value: 'API', child: Text('API')),
                      DropdownMenuItem(
                        value: 'BG_TASK',
                        child: Text('BG_TASK'),
                      ),
                      DropdownMenuItem(value: 'WIDGET', child: Text('WIDGET')),
                      DropdownMenuItem(value: 'NOTIF', child: Text('NOTIF')),
                      DropdownMenuItem(value: 'SYSTEM', child: Text('SYSTEM')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Log Message',
                      hintText: 'Enter test message...',
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final msg = textController.text.trim();
                    if (msg.isNotEmpty) {
                      AppLoggerService().log(msg, category: selectedCategory);
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = EtlabApiService();
    final logger = AppLoggerService();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Settings',
                    padding: const EdgeInsets.only(top: 10, bottom: 14),
                    actions: [
                      HeaderAction(
                        icon: Icons.notifications_outlined,
                        tooltip: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const ProfileAvatarAction(),
                    ],
                  ),
                  // Appearance Section
                  Text(
                    'APPEARANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ListenableBuilder(
                            listenable: ThemeService(),
                            builder: (context, _) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                title: const Text(
                                  'Theme Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'System default, light, or dark mode',
                                ),
                                trailing: SegmentedButton<ThemeMode>(
                                  segments: const [
                                    ButtonSegment(
                                      value: ThemeMode.system,
                                      icon: Icon(Icons.brightness_auto),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.light,
                                      icon: Icon(Icons.light_mode),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.dark,
                                      icon: Icon(Icons.dark_mode),
                                    ),
                                  ],
                                  selected: {ThemeService().themeMode},
                                  onSelectionChanged: (set) =>
                                      _applyThemeMode(set.first),
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: const Text(
                              'Accent Color',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              ThemeService().useDynamic
                                  ? 'System Dynamic (Matches Wallpaper)'
                                  : 'Custom Color',
                            ),
                            trailing: ThemeService().useDynamic
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 14,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Dynamic',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: ThemeService().seedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (sheetContext) {
                                  final isDynamic = ThemeService().useDynamic;
                                  final currentSeed = ThemeService().seedColor;

                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        20,
                                        24,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 36,
                                              height: 4,
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withAlpha(80),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Accent Color',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            'Match your phone wallpaper or choose a custom palette.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Dynamic System Option
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              ThemeService().setUseDynamic(
                                                true,
                                              );
                                              Navigator.pop(sheetContext);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isDynamic
                                                      ? theme
                                                            .colorScheme
                                                            .primary
                                                      : theme
                                                            .colorScheme
                                                            .outlineVariant
                                                            .withAlpha(120),
                                                  width: isDynamic ? 2 : 1,
                                                ),
                                                color: isDynamic
                                                    ? theme
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withAlpha(60)
                                                    : theme
                                                          .colorScheme
                                                          .surfaceContainerLow,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme
                                                          .primaryContainer,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.auto_awesome,
                                                      color: theme
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'System Dynamic (Material You)',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                        Text(
                                                          "Uses your phone's wallpaper accent color",
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isDynamic)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 16),
                                          Text(
                                            'PRESET COLORS',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            alignment: WrapAlignment.center,
                                            children: ThemeService.presetColors.entries.map((
                                              e,
                                            ) {
                                              final isSelected =
                                                  !isDynamic &&
                                                  e.value.toARGB32() ==
                                                      currentSeed.toARGB32();
                                              return GestureDetector(
                                                onTap: () {
                                                  ThemeService().setSeedColor(
                                                    e.value,
                                                    theme.brightness,
                                                  );
                                                  Navigator.pop(sheetContext);
                                                },
                                                child: SizedBox(
                                                  width: 58,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 38,
                                                        height: 38,
                                                        decoration: BoxDecoration(
                                                          color: e.value,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: isSelected
                                                              ? Border.all(
                                                                  color: theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                                  width: 3,
                                                                )
                                                              : Border.all(
                                                                  color: Colors
                                                                      .black12,
                                                                  width: 1,
                                                                ),
                                                        ),
                                                        child: isSelected
                                                            ? const Icon(
                                                                Icons.check,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        e.key[0].toUpperCase() +
                                                            e.key.substring(1),
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .bold
                                                                  : FontWeight
                                                                        .normal,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preferences Section
                  Text(
                    'PREFERENCES',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_notificationsEnabled != null) ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Enable Notifications',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Get notified when new absences are posted.',
                              ),
                              value: _notificationsEnabled!,
                              onChanged: (val) async {
                                if (val) {
                                  final systemGranted =
                                      await NotificationsService()
                                          .isSystemNotificationPermissionGranted();
                                  if (!systemGranted) {
                                    final granted =
                                        await NotificationsService()
                                            .requestPermission();
                                    if (!granted) {
                                      await NotificationsService()
                                          .openSystemNotificationSettings();
                                      return;
                                    }
                                  }
                                  setState(() {
                                    _notificationsEnabled = true;
                                  });
                                  await NotificationsService()
                                      .setNotificationsEnabled(true);
                                } else {
                                  setState(() {
                                    _notificationsEnabled = false;
                                  });
                                  await NotificationsService()
                                      .setNotificationsEnabled(false);
                                }
                              },
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Background Activity & Sync',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _backgroundStatus == null
                                    ? 'Check background activity and battery optimization status.'
                                    : switch (_backgroundStatus!['status']) {
                                        'unrestricted' =>
                                          'Unrestricted • Widgets and alerts sync reliably in background.',
                                        'restricted' =>
                                          'Restricted • Background tasks blocked by system. Tap to fix.',
                                        _ =>
                                          'Optimized • May be delayed by battery saver. Tap to configure.',
                                      },
                              ),
                              trailing: _buildBackgroundStatusBadge(theme),
                              onTap: _showBackgroundSyncDialog,
                            ),
                            const Divider(),
                          ],
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Target Attendance',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Minimum threshold for safe skips and recovery classes.',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${(api.targetAttendancePct * 100).round()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            onTap: () {
                              AttendanceSummaryWidget.showTargetDialog(
                                context,
                                onTargetChanged: () {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Dev Options',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Restricted. Enter the access code.',
                            ),
                            trailing: ValueListenableBuilder<bool>(
                              valueListenable: SafeWordService.unlocked,
                              builder: (context, unlocked, _) => Icon(
                                unlocked
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: _openSafeWordDialog,
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'How Navigation Works',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Replay the guided tour of the bottom dock.',
                            ),
                            trailing: const Icon(Icons.help_outline),
                            onTap: () => NavigationTutorial.show(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Account Section
                  Text(
                    'ACCOUNT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withAlpha(120),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Log Out',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            subtitle: const Text(
                              'Sign out of your student account on this device',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Function Execution & Background Logs (Debug Panel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DEBUG & DEVELOPER LOGS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          Text('Logging', style: theme.textTheme.labelSmall),
                          Switch(
                            value: logger.isDebugModeEnabled,
                            onChanged: (enabled) async {
                              await logger.setDebugMode(enabled);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Execution Schedule Monitor',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<List<LogEntry>>(
                                valueListenable: logger.logsNotifier,
                                builder: (context, currentLogs, _) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_comment_outlined,
                                          size: 20,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        tooltip: 'Add custom log',
                                        onPressed: _showAddCustomLogDialog,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy_outlined,
                                          size: 20,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        tooltip: 'Copy all logs',
                                        onPressed: currentLogs.isEmpty
                                            ? null
                                            : () => _copyAllLogs(currentLogs),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        tooltip: 'Clear logs',
                                        onPressed: currentLogs.isEmpty
                                            ? null
                                            : () {
                                                logger.clearLogs();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Logs cleared!',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick action buttons for developer testing
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: _isSyncing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync, size: 16),
                                label: const Text('Sync All Data'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: _isSyncing
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        setState(() => _isSyncing = true);
                                        logger.log(
                                          'Manual sync triggered from Settings',
                                          category: 'API',
                                        );
                                        try {
                                          await api.fetchAllData();
                                          logger.log(
                                            'Manual sync completed successfully',
                                            category: 'API',
                                          );
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Data synced successfully!',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          logger.log(
                                            'Manual sync failed: $e',
                                            category: 'ERROR',
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isSyncing = false);
                                          }
                                        }
                                      },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.widgets_outlined,
                                  size: 16,
                                ),
                                label: const Text('Refresh Widget'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  logger.log(
                                    'Triggering manual widget update...',
                                    category: 'WIDGET',
                                  );
                                  try {
                                    final timetable =
                                        DashboardDataMapper.parseTimetableFromProfile(
                                          api.profileData,
                                          subjectsData: api.attendanceData,
                                          teachersData: api.teachersData,
                                        );
                                    final attendance =
                                        DashboardDataMapper.parseAttendanceFromSubjects(
                                          api.attendanceData ?? api.profileData,
                                        );
                                    await HomeWidgetService.updateHomeScreenWidget(
                                      timetable: timetable,
                                      attendance: attendance,
                                      profileData: api.profileData,
                                      attendanceData: api.attendanceData,
                                      teachersData: api.teachersData,
                                    );
                                    logger.log(
                                      'Widget updated successfully',
                                      category: 'WIDGET',
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Widget refreshed!'),
                                      ),
                                    );
                                  } catch (e) {
                                    logger.log(
                                      'Widget update failed: $e',
                                      category: 'ERROR',
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Search Filter Box
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Filter logs (e.g. API, BG_TASK, WIDGET)...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _filterQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _filterQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (query) {
                              setState(() {
                                _filterQuery = query.trim().toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Logs List
                          ValueListenableBuilder<List<LogEntry>>(
                            valueListenable: logger.logsNotifier,
                            builder: (context, currentLogs, _) {
                              final filtered = _filterQuery.isEmpty
                                  ? currentLogs
                                  : currentLogs.where((l) {
                                      return l.message.toLowerCase().contains(
                                            _filterQuery,
                                          ) ||
                                          l.category.toLowerCase().contains(
                                            _filterQuery,
                                          );
                                    }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.notes,
                                          color: theme.colorScheme.outline,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _filterQuery.isNotEmpty
                                              ? 'No logs match filter.'
                                              : 'No log entries recorded yet.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(80),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 6, thickness: 0.5),
                                  itemBuilder: (context, index) {
                                    final entry = filtered[index];
                                    final catColor = _getCategoryColor(
                                      entry.category,
                                      theme,
                                    );

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: catColor.withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: catColor.withAlpha(100),
                                            ),
                                          ),
                                          child: Text(
                                            entry.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SelectableText(
                                                entry.message,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontFamily: 'monospace',
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                entry.formatTimestamp(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
