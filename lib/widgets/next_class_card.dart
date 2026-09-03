import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../screens/main_navigation_shell.dart';

class NextClassCardWidget extends StatelessWidget {
  final List<ClassSession> sessions;
  final bool isHoliday;
  final String? holidayReason;

  const NextClassCardWidget({
    super.key,
    required this.sessions,
    this.isHoliday = false,
    this.holidayReason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nowWeekday = DateTime.now().weekday;
    final bool isWeekend = nowWeekday == DateTime.saturday || nowWeekday == DateTime.sunday;

    if (isHoliday || isWeekend || sessions.isEmpty) {
      final String headerText;
      final String titleText;
      final String? subtitleText;
      final IconData iconData;

      if (isHoliday) {
        headerText = 'COLLEGE HOLIDAY';
        final reason = (holidayReason != null && holidayReason!.trim().isNotEmpty)
            ? holidayReason!.trim()
            : null;
        titleText = reason != null ? '$reason 🎉' : 'Today is a holiday! 🌴';
        subtitleText = 'Marked as a holiday on the academic calendar';
        iconData = Icons.celebration_outlined;
      } else if (isWeekend) {
        headerText = 'WEEKEND';
        titleText = 'Enjoy your weekend! 🌴';
        subtitleText = null;
        iconData = Icons.weekend_outlined;
      } else {
        headerText = 'NO CLASSES TODAY';
        titleText = 'No classes scheduled for today. 🎉';
        subtitleText = null;
        iconData = Icons.event_available_outlined;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: isHoliday
              ? () => MainNavigationShell.navigateToAttendance(context, initialTabIndex: 1)
              : null,
          child: Card(
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      size: 24,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitleText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitleText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bool isDoneForDay = sessions.isNotEmpty && sessions.every((s) => s.isPast);

    if (isDoneForDay) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 24,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLASSES FINISHED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All done for today! 🎉',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Find current or next upcoming class session
    final currentSession = sessions.firstWhere(
      (s) => s.isCurrent,
      orElse: () => sessions.firstWhere(
        (s) => !s.isPast,
        orElse: () => sessions.last,
      ),
    );

    final isCurrent = currentSession.isCurrent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: isCurrent
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(100),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final target = currentSession.courseName.isNotEmpty
                ? currentSession.courseName
                : currentSession.courseId;
            if (target.isNotEmpty) {
              MainNavigationShell.navigateToAttendance(
                context,
                highlightSubject: target,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCurrent ? 'CURRENT CLASS' : 'NEXT CLASS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      '${currentSession.start.format(context)} - ${currentSession.end.format(context)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currentSession.courseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (currentSession.room != null && currentSession.room!.isNotEmpty) ...[
                      Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(currentSession.room!, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                    ],
                    if (currentSession.teacherName != null && currentSession.teacherName!.isNotEmpty) ...[
                      Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentSession.teacherName!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
