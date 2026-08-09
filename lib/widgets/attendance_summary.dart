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

  @override
  State<AttendanceSummaryWidget> createState() => _AttendanceSummaryWidgetState();
}

class _AttendanceSummaryWidgetState extends State<AttendanceSummaryWidget> {
  void _openTargetDialog() {
    double currentPct = EtlabApiService().targetAttendancePct.clamp(0.75, 0.95);
    final presets = [0.75, 0.80, 0.85, 0.90, 0.95];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
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
                      '${(currentPct * 100).round()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Slider(
                    value: currentPct,
                    min: 0.75,
                    max: 0.95,
                    divisions: 20,
                    label: '${(currentPct * 100).round()}%',
                    onChanged: (val) {
                      setModalState(() {
                        currentPct = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: presets.map((p) {
                      final isSelected = (currentPct * 100).round() == (p * 100).round();
                      return FilterChip(
                        selected: isSelected,
                        label: Text('${(p * 100).round()}%'),
                        onSelected: (_) {
                          setModalState(() {
                            currentPct = p;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await EtlabApiService().setTargetAttendancePct(currentPct);
                        if (mounted && ctx.mounted) {
                          Navigator.pop(ctx);
                          setState(() {});
                          widget.onTargetChanged?.call();
                        }
                      },
                      child: const Text('Save Target'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
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

    final isSafe = pct >= attendance.requiredPercentage;
    final color = isSafe ? Colors.green : theme.colorScheme.error;
    final statusIcon = isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded;
    final statusText = isSafe ? "SAFE" : "CRITICAL";

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
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "DL: ${attendance.classesOnDutyLeave}",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.amber.shade900,
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: pct,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: color,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      pctText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
