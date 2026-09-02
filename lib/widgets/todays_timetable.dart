import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../screens/main_navigation_shell.dart';

class TodaysTimetableWidget extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? subjectsData;
  final Map<String, dynamic>? teachersData;
  final List<ClassSession>? initialSessions;

  const TodaysTimetableWidget({
    super.key,
    this.profileData,
    this.subjectsData,
    this.teachersData,
    this.initialSessions,
  });

  @override
  State<TodaysTimetableWidget> createState() => _TodaysTimetableWidgetState();
}

class _TodaysTimetableWidgetState extends State<TodaysTimetableWidget> {
  late List<String> _dayNames;
  late int _selectedDayIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initDayNames();
    _selectedDayIndex = _todayDayIndex ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSession(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant TodaysTimetableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSession(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initDayNames() {
    int count = 5;
    if (widget.profileData != null && widget.profileData!.containsKey('timetable')) {
      final rawTt = widget.profileData!['timetable'] as List<dynamic>;
      count = rawTt.length.clamp(5, 7);
    }
    const allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    _dayNames = allDays.sublist(0, count);
  }

  int? get _todayDayIndex {
    final nowWeekday = DateTime.now().weekday;
    final index = nowWeekday - 1;
    return (index >= 0 && index < _dayNames.length) ? index : null;
  }

  int _getTargetScrollIndex(List<ClassSession> sessions) {
    if (sessions.isEmpty) return 0;

    // 1. Current active class
    final currentIndex = sessions.indexWhere((s) => s.isCurrent);
    if (currentIndex != -1) return currentIndex;

    // 2. Next upcoming class (not past yet)
    final upcomingIndex = sessions.indexWhere((s) => !s.isPast);
    if (upcomingIndex != -1) return upcomingIndex;

    return 0;
  }

  void _scrollToActiveSession({bool animate = false}) {
    if (!mounted || !_scrollController.hasClients) return;

    final sessions = _getSessionsForDay();
    final isToday = _todayDayIndex != null && _selectedDayIndex == _todayDayIndex;
    final int targetIndex = isToday ? _getTargetScrollIndex(sessions) : 0;

    const double itemWidth = 243.0; // 235 card width + 8 horizontal margin
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double targetOffset = (targetIndex * itemWidth).clamp(0.0, maxScroll);

    if ((_scrollController.offset - targetOffset).abs() < 1.0) return;

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  void _prevDay() {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex - 1 + _dayNames.length) % _dayNames.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSession(animate: true);
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex + 1) % _dayNames.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSession(animate: true);
    });
  }

  List<ClassSession> _getSessionsForDay() {
    if (_todayDayIndex != null &&
        _selectedDayIndex == _todayDayIndex &&
        widget.initialSessions != null &&
        widget.initialSessions!.isNotEmpty) {
      return widget.initialSessions!;
    }
    return DashboardDataMapper.parseTimetableFromProfile(
      widget.profileData,
      dayIndex: _selectedDayIndex,
      subjectsData: widget.subjectsData,
      teachersData: widget.teachersData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = _getSessionsForDay();
    final isTodaySelected = _todayDayIndex != null && _selectedDayIndex == _todayDayIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Day Switcher Buttons on Each Side
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "TIMETABLE",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (isTodaySelected) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _scrollToActiveSession(animate: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TODAY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Day Switcher Controls (Button on each side of day name)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Previous Day',
                      onPressed: _prevDay,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _dayNames[_selectedDayIndex],
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Next Day',
                      onPressed: _nextDay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        if (sessions.isEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'No classes on ${_dayNames[_selectedDayIndex]}!',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _ClassCard(
                  session: session,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassSession session;

  const _ClassCard({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = session.isCurrent;
    final isPast = session.isPast && !isCurrent;

    Color cardBg = theme.colorScheme.surfaceContainerLow;
    Color borderBg = Colors.transparent;

    if (isCurrent) {
      cardBg = theme.colorScheme.primaryContainer.withAlpha(120);
      borderBg = theme.colorScheme.primary;
    }

    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Card(
        elevation: isCurrent ? 4 : 1,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrent ? borderBg : theme.colorScheme.outlineVariant.withAlpha(100),
            width: isCurrent ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          onTap: () {
            final target = session.courseName.isNotEmpty
                ? session.courseName
                : session.courseId;
            if (target.isNotEmpty) {
              MainNavigationShell.navigateToAttendance(
                context,
                highlightSubject: target,
              );
            }
          },
          child: Container(
            width: 235,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCurrent
                                  ? 'NOW • ${session.sessionType.toUpperCase()}'
                                  : session.sessionType.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isCurrent
                                    ? theme.colorScheme.onPrimary
                                    : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (session.courseId.isNotEmpty && session.courseId.toUpperCase() != session.courseName.toUpperCase()) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  session.courseId.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (session.status != null) _buildStatusBadge(theme, session.status!),
                  ],
                ),
                Text(
                  session.courseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (session.teacherName != null && session.teacherName!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.teacherName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      "${session.start.format(context)} - ${session.end.format(context)}",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (session.room != null && session.room!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        session.room!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, AttendanceStatus status) {
    final isDark = theme.brightness == Brightness.dark;
    IconData icon;
    Color fgColor;
    Color bgColor;
    String label;

    switch (status) {
      case AttendanceStatus.present:
        icon = Icons.check_circle_rounded;
        fgColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        bgColor = isDark ? const Color(0xFF14532D).withAlpha(150) : const Color(0xFFDCFCE7);
        label = "PRESENT";
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel_rounded;
        fgColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        bgColor = isDark ? const Color(0xFF7F1D1D).withAlpha(150) : const Color(0xFFFEE2E2);
        label = "ABSENT";
        break;
      case AttendanceStatus.dutyLeave:
        icon = Icons.assignment_turned_in_rounded;
        fgColor = isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E);
        bgColor = isDark ? const Color(0xFF713F12).withAlpha(150) : const Color(0xFFFEF08A);
        label = "DUTY LEAVE";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

