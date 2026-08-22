import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/month_calendar.dart';
import '../widgets/page_header.dart';
import 'notifications_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isTabMode;
  const AttendanceScreen({super.key, this.isTabMode = false});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedSemId;
  String? _selectedSemLabel;
  bool _isLoadingSemester = false;
  Map<String, dynamic>? _semesterSubjectsData;

  @override
  void initState() {
    super.initState();
    final api = EtlabApiService();
    _semesterSubjectsData = api.attendanceData ?? api.profileData;
    _fetchSemesters();
  }

  Future<void> _fetchSemesters() async {
    final api = EtlabApiService();
    if (api.semesterListData == null) {
      await api.fetchSemesterList();
      if (mounted) setState(() {});
    }
  }

  ({String? id, String label, int num}) _getCurrentSemesterInfo() {
    final profile = EtlabApiService().profileData;
    if (profile == null) {
      return (id: null, label: 'Semester 5 (Current)', num: 5);
    }

    final data =
        profile['student'] ?? profile['profile'] ?? profile['data'] ?? profile;
    final semId =
        (data['sem_id'] ?? data['semester_id'] ?? data['current_sem_id'])
            ?.toString();
    final semName =
        (data['semester'] ??
                data['sem'] ??
                data['semester_name'] ??
                data['current_semester'])
            ?.toString();

    final semNum =
        int.tryParse(
          RegExp(r'\d+').firstMatch(semName ?? semId ?? '')?.group(0) ?? '',
        ) ??
        5;
    return (id: semId, label: semName ?? 'Semester $semNum', num: semNum);
  }

  Future<void> _changeSemester(String? semId, String? label) async {
    if (_selectedSemId == semId) return;

    final api = EtlabApiService();

    Map<String, dynamic>? cachedData;
    if (semId != null) {
      cachedData = await api.getCachedSemesterAttendance(semId);
    }

    if (cachedData != null && mounted) {
      setState(() {
        _selectedSemId = semId;
        _selectedSemLabel = label;
        _semesterSubjectsData = cachedData;
        _isLoadingSemester = false;
      });
    } else {
      setState(() {
        _selectedSemId = semId;
        _selectedSemLabel = label;
        _isLoadingSemester = true;
      });
    }

    try {
      final res = await api.fetchAttendanceBySubject(semester: semId);

      if (!mounted) return;

      if (res != null) {
        if (semId != null) {
          await api.cacheSemesterAttendance(semId, res);
        }
        setState(() {
          _semesterSubjectsData = res;
          _isLoadingSemester = false;
        });
      } else if (cachedData == null) {
        setState(() {
          _isLoadingSemester = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (cachedData == null) {
        setState(() {
          _isLoadingSemester = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSubjectwiseTab(ThemeData theme) {
    final api = EtlabApiService();
    final rawSemList = api.semesterListData ?? [];
    final subjectsData =
        _semesterSubjectsData ?? api.attendanceData ?? api.profileData;
    final attendanceList = DashboardDataMapper.parseAttendanceFromSubjects(
      subjectsData,
    );

    final currentSemInfo = _getCurrentSemesterInfo();
    final List<({String id, String label, bool isCurrent})> options = [];

    if (rawSemList.isNotEmpty) {
      for (int i = 0; i < rawSemList.length; i++) {
        final item = rawSemList[i] is Map<String, dynamic>
            ? (rawSemList[i] as Map<String, dynamic>)
            : <String, dynamic>{};
        final id =
            (item['sem_id'] ?? item['id'] ?? item['semester_id'] ?? '${i + 1}')
                .toString();
        final labelStr =
            (item['semester'] ??
                    item['semester_name'] ??
                    item['name'] ??
                    'Semester ${i + 1}')
                .toString();
        final itemNum =
            int.tryParse(
              RegExp(
                    r'\d+',
                  ).firstMatch(labelStr.isNotEmpty ? labelStr : id)?.group(0) ??
                  '',
            ) ??
            (i + 1);

        if (itemNum > currentSemInfo.num) continue;

        final isCurrent =
            (currentSemInfo.id != null && id == currentSemInfo.id) ||
            itemNum == currentSemInfo.num;
        options.add((
          id: id,
          label: isCurrent ? '$labelStr (Current)' : labelStr,
          isCurrent: isCurrent,
        ));
      }
    }

    if (options.isEmpty) {
      for (int semNum = 1; semNum <= currentSemInfo.num; semNum++) {
        final isCurrent = (semNum == currentSemInfo.num);
        options.add((
          id: semNum.toString(),
          label: isCurrent ? 'Semester $semNum (Current)' : 'Semester $semNum',
          isCurrent: isCurrent,
        ));
      }
    }

    final currentOption = options.firstWhere(
      (o) => o.isCurrent,
      orElse: () => options.last,
    );
    final activeId = _selectedSemId ?? currentOption.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(100),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SEMESTER',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeId,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        items: options.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt.id,
                            child: Text(opt.label),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId == null) return;
                          final match = options.firstWhere(
                            (o) => o.id == newId,
                          );
                          _changeSemester(
                            match.isCurrent ? null : newId,
                            match.label,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingSemester)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (attendanceList.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No attendance data found for ${_selectedSemLabel ?? "selected semester"}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            AttendanceSummaryWidget(
              attendanceList: attendanceList,
              dutyLeaveCountsAsPresent: true,
              onTargetChanged: () {
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Attendance',
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
                ],
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'By Subject'),
                  Tab(text: 'By Day'),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: TabBarView(
                      children: [
                        // Tab 1: Subjectwise Attendance
                        _buildSubjectwiseTab(theme),
                        // Tab 2: Dynamic Attendance Calendar View
                        const MonthCalendar(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
