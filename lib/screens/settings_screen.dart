import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_logger_service.dart';
import '../services/etlab_api_service.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  double? _sliderTargetPct;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logger = AppLoggerService();
    final api = EtlabApiService();
    final currentTarget = _sliderTargetPct ?? api.targetAttendancePct;

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
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Attendance',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(currentTarget * 100).round()}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minimum threshold used to calculate safe skips and recovery classes.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Slider(
                          value: currentTarget.clamp(0.75, 1.0),
                          min: 0.75,
                          max: 1.0,
                          divisions: 25,
                          label: '${(currentTarget * 100).round()}%',
                          onChanged: (val) {
                            setState(() {
                              _sliderTargetPct = val;
                            });
                          },
                          onChangeEnd: (val) async {
                            await api.setTargetAttendancePct(val);
                            if (mounted) {
                              setState(() {
                                _sliderTargetPct = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Function Execution & Background Logs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FUNCTION & BACKGROUND LOGS',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.schedule_outlined, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Execution Schedule Monitor',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                      icon: const Icon(Icons.copy_outlined, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      tooltip: 'Copy all logs',
                                      onPressed: currentLogs.isEmpty ? null : () => _copyAllLogs(currentLogs),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      tooltip: 'Clear logs',
                                      onPressed: currentLogs.isEmpty
                                          ? null
                                          : () {
                                              logger.clearLogs();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Logs cleared!'),
                                                  duration: Duration(seconds: 1),
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
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Filter logs (e.g. BG_TASK, WIDGET, API)...',
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        ValueListenableBuilder<List<LogEntry>>(
                          valueListenable: logger.logsNotifier,
                          builder: (context, currentLogs, _) {
                            final filtered = _filterQuery.isEmpty
                                ? currentLogs
                                : currentLogs.where((l) {
                                    return l.message.toLowerCase().contains(_filterQuery) ||
                                        l.category.toLowerCase().contains(_filterQuery);
                                  }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.notes, color: theme.colorScheme.outline, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        _filterQuery.isNotEmpty ? 'No logs match filter.' : 'No log entries recorded yet.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Container(
                              height: 340,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 6, thickness: 0.5),
                                itemBuilder: (context, index) {
                                  final entry = filtered[index];
                                  final catColor = _getCategoryColor(entry.category, theme);

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: catColor.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: catColor.withAlpha(100)),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SelectableText(
                                              entry.message,
                                              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              entry.formatTimestamp(),
                                              style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
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
    );
  }
}
