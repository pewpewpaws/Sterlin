import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/month_calendar.dart';
import '../widgets/page_header.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String? highlightSubject;

  const AttendanceScreen({super.key, this.highlightSubject});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _currentSemesterLabel() {
    final profile = EtlabApiService().profileData;
    if (profile == null) return 'Current Semester';

    final data =
        profile['student'] ?? profile['profile'] ?? profile['data'] ?? profile;
    final semName =
        (data['curnt_sem'] ??
                data['semester'] ??
                data['sem'] ??
                data['semester_name'])
            ?.toString()
            .trim();
    if (semName != null && semName.isNotEmpty) return semName;

    final semNum = int.tryParse(
          RegExp(r'\d+')
              .firstMatch(
                (data['sem_id'] ?? data['semester_id'] ?? '').toString(),
              )
              ?.group(0) ??
            '',
        ) ??
        5;
    return 'Semester $semNum';
  }

  Future<void> _refreshCurrentSemester() async {
    await EtlabApiService().fetchAttendanceBySubject();
    if (mounted) setState(() {});
  }

  Widget _buildSubjectwiseTab(ThemeData theme) {
    final api = EtlabApiService();
    final subjectsData = api.attendanceData ?? api.profileData;
    final attendanceList = DashboardDataMapper.parseAttendanceFromSubjects(
      subjectsData,
    );
    final semLabel = _currentSemesterLabel();

    return RefreshIndicator(
      onRefresh: _refreshCurrentSemester,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      semLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CURRENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (attendanceList.isEmpty)
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
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No attendance records yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pull down to refresh.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              AttendanceSummaryWidget(
                attendanceList: attendanceList,
                dutyLeaveCountsAsPresent: true,
                highlightSubject: widget.highlightSubject,
                onTargetChanged: () {
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const ProfileAvatarAction(),
                ],
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'By Subject'),
                  Tab(text: 'By Day'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildSubjectwiseTab(Theme.of(context)),
                    const MonthCalendar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
