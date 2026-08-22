import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';

class AttendanceSummaryWidget extends StatefulWidget {
  final List<CourseAttendance> attendanceList;
  final bool dutyLeaveCountsAsPresent;
  final VoidCallback? onTargetChanged;

  const AttendanceSummaryWidget({
    super.key,
    required this.attendanceList,
    this.dutyLeaveCountsAsPresent = true,
    this.onTargetChanged,
  });

  static Future<void> showTargetDialog(
    BuildContext context, {
    VoidCallback? onTargetChanged,
  }) async {
    int currentIntPct = (EtlabApiService().targetAttendancePct * 100).round().clamp(75, 95);
    final presets = [75, 80, 85, 90, 95];

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            Future<void> applyTarget() async {
              await EtlabApiService()
                  .setTargetAttendancePct(currentIntPct / 100.0);
              onTargetChanged?.call();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Attendance',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your target percentage (75% min) to recalculate how many classes you can skip or need to recover.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '$currentIntPct%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Slider(
                    value: currentIntPct.toDouble(),
                    min: 75,
                    max: 95,
                    divisions: 20,
                    label: '$currentIntPct%',
                    onChanged: (val) {
                      setModalState(() {
                        currentIntPct = val.round();
                      });
                    },
                    onChangeEnd: (_) => applyTarget(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: presets.map((p) {
                        final isSelected = currentIntPct == p;
                        return FilterChip(
                          selected: isSelected,
                          label: Text('$p%'),
                          onSelected: (_) {
                            setModalState(() {
                              currentIntPct = p;
                            });
                            applyTarget();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<AttendanceSummaryWidget> createState() => _AttendanceSummaryWidgetState();
}

class _AttendanceSummaryWidgetState extends State<AttendanceSummaryWidget> {
  void _openTargetDialog() {
    AttendanceSummaryWidget.showTargetDialog(
      context,
      onTargetChanged: () {
        if (mounted) {
          setState(() {});
          widget.onTargetChanged?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetPct = EtlabApiService().targetAttendancePct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ATTENDANCE SUMMARY",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              InkWell(
                onTap: _openTargetDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_outlined, size: 14, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${(targetPct * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.attendanceList.length,
          itemBuilder: (context, index) {
            final item = widget.attendanceList[index];
            return _AttendanceCard(
              attendance: item,
              dutyLeaveCountsAsPresent: widget.dutyLeaveCountsAsPresent,
            );
          },
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final CourseAttendance attendance;
  final bool dutyLeaveCountsAsPresent;

  const _AttendanceCard({
    required this.attendance,
    required this.dutyLeaveCountsAsPresent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = attendance.calculatePercentage(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);
    final pctText = "${(pct * 100).round()}%";
    final hintText = attendance.getBunkOrRecoverHint(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);

    final isDark = theme.brightness == Brightness.dark;
    final isSafe = pct >= attendance.requiredPercentage;
    final isOnBoundary = attendance.isOnBoundary(dutyLeaveCountsAsPresent: dutyLeaveCountsAsPresent);

    final Color color;
    final IconData statusIcon;
    final String statusText;

    if (!isSafe) {
      color = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      statusIcon = Icons.warning_amber_rounded;
      statusText = "CRITICAL";
    } else if (isOnBoundary) {
      color = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      statusIcon = Icons.warning_amber_rounded;
      statusText = "BOUNDARY";
    } else {
      color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      statusIcon = Icons.check_circle_rounded;
      statusText = "SAFE";
    }

    final total = dutyLeaveCountsAsPresent
        ? attendance.classesAttended + attendance.classesOnDutyLeave + attendance.classesAbsent
        : attendance.classesAttended + attendance.classesAbsent;
    final attended = dutyLeaveCountsAsPresent
        ? attendance.classesAttended + attendance.classesOnDutyLeave
        : attendance.classesAttended;
    final attendedTotalText = "$attended / $total";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendance.courseName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(statusIcon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (attendance.classesOnDutyLeave > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF713F12).withAlpha(150)
                                : const Color(0xFFFEF08A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "DL: ${attendance.classesOnDutyLeave}",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? const Color(0xFFFDE047)
                                  : const Color(0xFF854D0E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hintText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pctText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attendedTotalText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
