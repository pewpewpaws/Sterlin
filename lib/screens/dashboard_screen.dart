import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../services/home_widget_service.dart';
import '../services/background_service.dart';
import '../services/notifications_service.dart';
import '../widgets/todays_timetable.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/dashboard_tiles.dart';
import '../widgets/next_class_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import 'teachers_screen.dart';
import 'attendance_screen.dart';
import 'notifications_screen.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum DashboardWidgetType {
  nextClass,
  timetable,
  attendance,
  quickAccess,
}

extension DashboardWidgetTypeExtension on DashboardWidgetType {
  String get title {
    switch (this) {
      case DashboardWidgetType.nextClass:
        return "Next / Current Class Focus";
      case DashboardWidgetType.timetable:
        return "Today's Timetable";
      case DashboardWidgetType.attendance:
        return "Today's Attendance Summary";
      case DashboardWidgetType.quickAccess:
        return "Quick Access Shortcuts";
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
      case DashboardWidgetType.quickAccess:
        return Icons.grid_view;
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<ClassSession> _timetable;
  late List<CourseAttendance> _attendance;
  bool _dutyLeaveCountsAsPresent = true;
  bool _isLoading = false;

  // All widgets and their order
  List<DashboardWidgetType> _widgetOrder = [
    DashboardWidgetType.nextClass,
    DashboardWidgetType.timetable,
    DashboardWidgetType.attendance,
    DashboardWidgetType.quickAccess,
  ];

  // Active home screen widgets
  final Set<DashboardWidgetType> _activeWidgets = {
    DashboardWidgetType.nextClass,
    DashboardWidgetType.timetable,
    DashboardWidgetType.attendance,
    DashboardWidgetType.quickAccess,
  };

  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadDataFromApi();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && EtlabApiService().profileData != null) {
        _refreshData();
        BackgroundService.scheduleNextRefresh();
        NotificationsService().requestPermission();
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(() {
      _hasInternet = !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
      _attendance = DashboardDataMapper.parseAttendanceFromSubjects(subjects ?? profile);
    });

    HomeWidgetService.updateHomeScreenWidget(
      timetable: _timetable,
      attendance: _attendance,
    );
  }

  // Filter attendance for the current day's subjects only
  List<CourseAttendance> get _todaysAttendance {
    if (_timetable.isEmpty) return [];

    final todaysCourseIds = _timetable.map((s) => s.courseId.toLowerCase()).toSet();
    final todaysCourseNames = _timetable.map((s) => s.courseName.toLowerCase()).toSet();

    final filtered = _attendance.where((a) {
      final cId = a.courseId.toLowerCase();
      final cName = a.courseName.toLowerCase();
      return todaysCourseIds.contains(cId) || todaysCourseNames.contains(cName);
    }).toList();

    return filtered.isNotEmpty ? filtered : _attendance;
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await EtlabApiService().fetchAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    _loadDataFromApi();
    setState(() {
      _isLoading = false;
    });
  }

  void _handleTileTap(String route) {
    if (route == '/faculty') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TeachersScreen()),
      );
    } else if (route == '/attendance') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Navigation section: $route"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                Icon(widgetType.icon, color: Theme.of(context).colorScheme.primary),
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

  Future<void> _logout() async {
    await EtlabApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildDashboardWidget(DashboardWidgetType type, Map<String, dynamic>? profile) {
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
      case DashboardWidgetType.quickAccess:
        return DashboardTilesWidget(onTileTap: _handleTileTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = EtlabApiService().profileData;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sterlin'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: const DashboardSkeletonLoader(),
      );
    }

    final studentName = profile['name']?.toString() ?? 'Student';
    final regNo = profile['register_no']?.toString() ?? profile['student_id']?.toString() ?? '';
    final sem = profile['curnt_sem']?.toString() ?? '';
    final photoUrl = profile['url']?.toString();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      appBar: AppBar(
        title: const Text('Sterlin'),
        centerTitle: false,
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
          IconButton(
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Customize Widgets',
            onPressed: _openWidgetCustomizer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasInternet)
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              // User Profile Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: (photoUrl != null && photoUrl.startsWith('http'))
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || !photoUrl.startsWith('http'))
                              ? Text(
                                  studentName.isNotEmpty ? studentName[0] : 'S',
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              if (regNo.isNotEmpty)
                                Text(
                                  'Reg: $regNo',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              if (sem.isNotEmpty)
                                Text(
                                  sem,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
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
              if (_isLoading) const Center(child: LinearProgressIndicator()),

              // Active Dashboard Widgets
              ..._widgetOrder.where((w) => _activeWidgets.contains(w)).map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDashboardWidget(type, profile),
              )),

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
  }
}
