import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../services/home_widget_service.dart';
import '../services/background_service.dart';
import '../services/notifications_service.dart';
import '../widgets/todays_timetable.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/next_class_card.dart';
import '../widgets/navigation_tutorial.dart';
import '../widgets/page_header.dart';
import 'notifications_screen.dart';

enum DashboardWidgetType { nextClass, timetable, attendance }

extension DashboardWidgetTypeExtension on DashboardWidgetType {
  String get title {
    switch (this) {
      case DashboardWidgetType.nextClass:
        return "Next / Current Class Focus";
      case DashboardWidgetType.timetable:
        return "Today's Timetable";
      case DashboardWidgetType.attendance:
        return "Today's Attendance Summary";
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardWidgetType.nextClass:
        return Icons.bolt;
      case DashboardWidgetType.timetable:
        return Icons.calendar_today_outlined;
      case DashboardWidgetType.attendance:
        return Icons.pie_chart_outline;
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late List<ClassSession> _timetable;
  late List<CourseAttendance> _attendance;
  final bool _dutyLeaveCountsAsPresent = true;
  bool _isLoading = false;

  // All widgets and their order
  final List<DashboardWidgetType> _widgetOrder = [
    DashboardWidgetType.nextClass,
    DashboardWidgetType.timetable,
    DashboardWidgetType.attendance,
  ];

  // Active home screen widgets
  final Set<DashboardWidgetType> _activeWidgets = {
    DashboardWidgetType.nextClass,
    DashboardWidgetType.timetable,
    DashboardWidgetType.attendance,
  };

  @override
  void initState() {
    super.initState();
    _loadDataFromApi();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && EtlabApiService().profileData != null) {
        _refreshData();
        BackgroundService.scheduleNextRefresh();
        NavigationTutorial.waitForFirstRun.then((_) async {
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) await _checkAndPromptNotificationPermission();
        });
      }
    });
  }

  Future<void> _checkAndPromptNotificationPermission() async {
    final notifService = NotificationsService();
    final hasPrompted = await notifService.hasPromptedPermission();
    if (!hasPrompted && mounted) {
      await notifService.setPromptedPermission(true);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Absent Tracker',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Sterlin uses notifications to immediately alert you whenever absences or attendance changes are recorded. You can easily turn this on or off anytime in Settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await notifService.setNotificationsEnabled(false);
                },
                child: const Text('Not Now'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await notifService.setNotificationsEnabled(true);
                },
                child: const Text('Enable Notifications'),
              ),
            ],
          );
        },
      );
    }
  }

  void _loadDataFromApi() {
    final api = EtlabApiService();
    final profile = api.profileData;
    final subjects = api.attendanceData;
    final teachers = api.teachersData;

    setState(() {
      _timetable = DashboardDataMapper.parseTimetableFromProfile(
        profile,
        subjectsData: subjects,
        teachersData: teachers,
      );
      _attendance = DashboardDataMapper.parseAttendanceFromSubjects(
        subjects ?? profile,
      );
    });

    HomeWidgetService.updateHomeScreenWidget(
      timetable: _timetable,
      attendance: _attendance,
      profileData: profile,
      attendanceData: subjects,
      teachersData: teachers,
    );
  }

  // Filter attendance for the current day's subjects only
  List<CourseAttendance> get _todaysAttendance {
    if (_timetable.isEmpty) return [];

    final todaysCourseIds = _timetable
        .map((s) => s.courseId.toLowerCase())
        .toSet();
    final todaysCourseNames = _timetable
        .map((s) => s.courseName.toLowerCase())
        .toSet();

    final filtered = _attendance.where((a) {
      final idMatch = todaysCourseIds.contains(a.courseId.toLowerCase());
      final nameMatch = todaysCourseNames.contains(a.courseName.toLowerCase());
      return idMatch || nameMatch;
    }).toList();

    return filtered.isNotEmpty ? filtered : _attendance;
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final api = EtlabApiService();
      await api.fetchAllData();
      if (!mounted) return;
      _loadDataFromApi();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _openWidgetCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customize Home Widgets',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select and reorder widgets for your home dashboard:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ReorderableListView(
                        shrinkWrap: true,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          setModalState(() {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = _widgetOrder.removeAt(oldIndex);
                              _widgetOrder.insert(newIndex, item);
                            });
                          });
                        },
                        children: _widgetOrder.map((widgetType) {
                          final isEnabled = _activeWidgets.contains(widgetType);
                          return CheckboxListTile(
                            key: ValueKey(widgetType.toString()),
                            value: isEnabled,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Row(
                              children: [
                                Icon(
                                  widgetType.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Text(widgetType.title)),
                              ],
                            ),
                            secondary: const Icon(Icons.drag_handle),
                            onChanged: (bool? value) {
                              setModalState(() {
                                setState(() {
                                  if (value == true) {
                                    _activeWidgets.add(widgetType);
                                  } else {
                                    _activeWidgets.remove(widgetType);
                                  }
                                });
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
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

  Widget _buildDashboardWidget(
    DashboardWidgetType type,
    Map<String, dynamic>? profile,
  ) {
    switch (type) {
      case DashboardWidgetType.nextClass:
        return NextClassCardWidget(sessions: _timetable);
      case DashboardWidgetType.timetable:
        return TodaysTimetableWidget(
          profileData: profile,
          subjectsData: EtlabApiService().attendanceData,
          teachersData: EtlabApiService().teachersData,
          initialSessions: _timetable,
        );
      case DashboardWidgetType.attendance:
        return AttendanceSummaryWidget(
          attendanceList: _todaysAttendance,
          dutyLeaveCountsAsPresent: _dutyLeaveCountsAsPresent,
          onTargetChanged: () {
            _loadDataFromApi();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = EtlabApiService().profileData;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final studentName = profile['name']?.toString() ?? 'Student';
    final regNo =
        profile['register_no']?.toString() ??
        profile['student_id']?.toString() ??
        '';
    final sem = profile['curnt_sem']?.toString() ?? '';
    final photoUrl = profile['url']?.toString();

    Widget bodyContent = RefreshIndicator(
      onRefresh: _refreshData,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top-left greeting header
                  _buildHomeHeader(context, theme, studentName),
                  // User Profile Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primary,
                              backgroundImage:
                                  (photoUrl != null &&
                                      photoUrl.startsWith('http'))
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child:
                                  (photoUrl == null ||
                                      !photoUrl.startsWith('http'))
                                  ? Text(
                                      studentName.isNotEmpty
                                          ? studentName[0]
                                          : 'S',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                  ),
                                  if (regNo.isNotEmpty)
                                    Text(
                                      'Reg: $regNo',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  if (sem.isNotEmpty)
                                    Text(
                                      sem,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isLoading)
                    const Center(child: LinearProgressIndicator()),

                  // Active Dashboard Widgets
                  ..._widgetOrder
                      .where((w) => _activeWidgets.contains(w))
                      .map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDashboardWidget(type, profile),
                        ),
                      ),

                  // Add Widget Button Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton.icon(
                        onPressed: _openWidgetCustomizer,
                        icon: const Icon(Icons.add),
                        label: const Text('Add / Customize Widgets'),
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

    return Scaffold(body: bodyContent);
  }

  /// Top-left greeting header: eyebrow greeting + student name, with the
  /// page actions on the right.
  Widget _buildHomeHeader(
    BuildContext context,
    ThemeData theme,
    String studentName,
  ) {
    final firstName = studentName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  firstName,
                  style: theme.textTheme.displaySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          HeaderAction(
            icon: Icons.widgets_outlined,
            tooltip: 'Customize Widgets',
            onTap: _openWidgetCustomizer,
          ),
          const SizedBox(width: 10),
          HeaderAction(
            icon: Icons.refresh,
            tooltip: 'Refresh Data',
            onTap: _refreshData,
          ),
          const SizedBox(width: 10),
          HeaderAction(
            key: NavigationTutorial.bellKey,
            icon: Icons.notifications_outlined,
            tooltip: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
