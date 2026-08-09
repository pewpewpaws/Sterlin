import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_logger_service.dart';
import '../services/etlab_api_service.dart';
import '../services/lockscreen_notification_service.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  bool _lockscreenEnabled = true;
  bool _lockscreenLoaded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCalendarArchiveDialog() async {
    final api = EtlabApiService();
    final months = await api.getStoredCalendarMonths();
    final allDays = await api.getAllArchivedCalendarData();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final jsonString = const JsonEncoder.withIndent('  ').convert(allDays);
        return AlertDialog(
          title: const Text('Calendar Storage Archive'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archived Months (${months.length}): ${months.isEmpty ? "None yet" : months.join(", ")}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Total Recorded Days: ${allDays.length}'),
                const SizedBox(height: 12),
                const Text('Master Calendar Database:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString.isEmpty ? '{}' : jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy JSON Archive'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calendar archive JSON copied!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddCustomLogDialog() {
    final textController = TextEditingController();
    final categoryController = TextEditingController(text: 'CUSTOM');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Custom Log Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Tag / Category',
                  hintText: 'CUSTOM, DEBUG, TEST...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Log Message',
                  hintText: 'Type your custom debug note or variable payload here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final msg = textController.text.trim();
                final cat = categoryController.text.trim().isEmpty ? 'CUSTOM' : categoryController.text.trim();
                if (msg.isNotEmpty) {
                  AppLoggerService().log(msg, category: cat);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom log entry added!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('Add Log'),
            ),
          ],
        );
      },
    );
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

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'API':
        return Colors.blue;
      case 'SYSTEM':
        return Colors.teal;
      case 'CUSTOM':
        return Colors.purple;
      case 'ERROR':
        return theme.colorScheme.error;
      case 'CACHE':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logger = AppLoggerService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings Section Header
                Text(
                  'DEVELOPER SETTINGS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),

                // Debug Logging Toggle Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                  ),
                  child: SwitchListTile(
                    value: logger.isDebugModeEnabled,
                    title: const Text('Enable Developer Debug Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Capture API requests, responses, cache events, and custom notes.'),
                    onChanged: (enabled) async {
                      await logger.setDebugMode(enabled);
                      setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'NOTIFICATIONS',
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
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                  ),
                  child: SwitchListTile(
                    value: _lockscreenEnabled,
                    title: const Text('Lock-screen next-class', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Show your next class on the lock screen and notification shade.'),
                    onChanged: _lockscreenLoaded
                        ? (enabled) async {
                            await LockscreenNotificationService().setEnabled(enabled);
                            setState(() {
                              _lockscreenEnabled = enabled;
                            });
                          }
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'CALENDAR STORAGE ARCHIVE',
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
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                    title: const Text('View Stored Calendar Database', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Inspect or export all historically archived month payloads saved in local storage.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showCalendarArchiveDialog,
                  ),
                ),

                const SizedBox(height: 16),

                // Debug Logs Pane (Visible when Debug Mode is ON)
                if (logger.isDebugModeEnabled) ...[
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.terminal_outlined, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DEBUG LOG VIEWER',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<List<LogEntry>>(
                                valueListenable: logger.logsNotifier,
                                builder: (context, currentLogs, _) {
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_outlined),
                                        tooltip: 'Copy all logs',
                                        onPressed: currentLogs.isEmpty ? null : () => _copyAllLogs(currentLogs),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Clear logs',
                                        onPressed: currentLogs.isEmpty
                                            ? null
                                            : () {
                                                logger.clearLogs();
                                              },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Action button to add custom log entry
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_comment_outlined, size: 18),
                              label: const Text('Add Custom Log Entry'),
                              onPressed: _showAddCustomLogDialog,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Filter Search TextField
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Filter logs by keyword...',
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _filterQuery = val.trim().toLowerCase();
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          // Log List View
                          ValueListenableBuilder<List<LogEntry>>(
                            valueListenable: logger.logsNotifier,
                            builder: (context, currentLogs, _) {
                              final filtered = currentLogs.where((l) {
                                if (_filterQuery.isEmpty) return true;
                                return l.message.toLowerCase().contains(_filterQuery) ||
                                    l.category.toLowerCase().contains(_filterQuery);
                              }).toList();

                              if (currentLogs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No logs captured yet. Perform actions or add a custom log above!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              if (filtered.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No logs match your filter.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final log = filtered[index];
                                    final badgeColor = _getCategoryColor(log.category, theme);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: badgeColor.withAlpha(100)),
                                                ),
                                                child: Text(
                                                  log.category,
                                                  style: TextStyle(
                                                    color: badgeColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                log.formatTimestamp(),
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.outline,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          SelectableText(
                                            log.message,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
