import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

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

  @override
  void initState() {
    super.initState();
    _initDayNames();
    _selectedDayIndex = _todayDayIndex;
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

  int get _todayDayIndex {
    final nowWeekday = DateTime.now().weekday;
    final index = nowWeekday - 1;
    return (index >= 0 && index < _dayNames.length) ? index : 0;
  }

  void _prevDay() {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex - 1 + _dayNames.length) % _dayNames.length;
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex + 1) % _dayNames.length;
    });
  }

  List<ClassSession> _getSessionsForDay() {
    if (_selectedDayIndex == _todayDayIndex && widget.initialSessions != null && widget.initialSessions!.isNotEmpty) {
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
    final isTodaySelected = _selectedDayIndex == _todayDayIndex;

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TODAY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
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
            height: 175,
            child: ListView.builder(
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
          side: BorderSide(color: borderBg, width: isCurrent ? 2 : 0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.sessionType.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
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
    );
  }

  Widget _buildStatusBadge(ThemeData theme, AttendanceStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case AttendanceStatus.present:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel;
        color = theme.colorScheme.error;
        break;
      case AttendanceStatus.dutyLeave:
        icon = Icons.assignment_turned_in;
        color = Colors.amber.shade800;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, size: 16, color: color);
  }
}

