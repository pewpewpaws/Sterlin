import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/absence_detail.dart';
import '../services/notifications_service.dart';
import '../services/theme_service.dart';
import '../widgets/page_header.dart';
import 'main_navigation_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _newAbsences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final service = NotificationsService();
    final absences = await service.getNewAbsences();

    if (mounted) {
      setState(() {
        _newAbsences = absences;
        _isLoading = false;
      });
    }
  }

  Future<void> _markDone(String key) async {
    HapticFeedback.lightImpact();
    final service = NotificationsService();
    await service.markAsRead(key);
    if (mounted) {
      setState(() {
        _newAbsences.removeWhere((item) => (item['key'] ?? '') == key);
      });
    }
    await service.updateUnreadCount();
  }

  Future<void> _markAllDone() async {
    HapticFeedback.mediumImpact();
    final service = NotificationsService();
    await service.markAllAsRead();
    if (mounted) {
      setState(() {
        _newAbsences.clear();
      });
    }
    await service.updateUnreadCount();
  }

  void _openAbsenceCalendar(String dateStr, String subject) {
    DateTime? parsedDate;
    if (dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }
    Navigator.pop(context);
    MainNavigationShell.navigateToAttendance(
      context,
      highlightSubject: subject,
      targetDate: parsedDate,
      initialTabIndex: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Notifications',
              actions: [
                if (_newAbsences.isNotEmpty)
                  TextButton.icon(
                    onPressed: _markAllDone,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Clear All'),
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _newAbsences.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              100,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No new absences recorded.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _newAbsences.length,
                      itemBuilder: (context, index) {
                        final raw = _newAbsences[index];
                        final absence = AbsenceDetail.resolve(raw);

                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerLow,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(120),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Status Row: Date & Day + Period + ABSENT chip
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer
                                            .withAlpha(160),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        color: theme.colorScheme.error,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            absence.dayName.isNotEmpty
                                                ? '${absence.dayName}, ${absence.formattedDate}'
                                                : absence.formattedDate,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily:
                                                      ThemeService
                                                          .displayFontFamily,
                                                ),
                                          ),
                                          if (absence.hour.isNotEmpty)
                                            Text(
                                              'Period ${absence.hour}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'ABSENT',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onErrorContainer,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1, thickness: 0.8),
                                const SizedBox(height: 12),
                                // Subject Code Box + Full Subject Name
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (absence.subjectCode.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withAlpha(60),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          absence.subjectCode,
                                          style: TextStyle(
                                            fontFamily:
                                                ThemeService.displayFontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: Text(
                                        absence.subjectName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Teacher / Faculty Name
                                if (absence.teacherName != null &&
                                    absence.teacherName!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 15,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          absence.teacherName!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Actions Row: Dedicated Done Button + View in Calendar Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _markDone(absence.key),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor:
                                            theme.colorScheme.onSurfaceVariant,
                                        side: BorderSide(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Done'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openAbsenceCalendar(
                                        absence.date,
                                        absence.rawSubject,
                                      ),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('View Absence'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
