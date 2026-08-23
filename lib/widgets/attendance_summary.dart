import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../services/safeword_service.dart';

class AttendanceSummaryWidget extends StatefulWidget {
  final List<CourseAttendance> attendanceList;
  final bool dutyLeaveCountsAsPresent;
  final VoidCallback? onTargetChanged;
  final String? highlightSubject;

  const AttendanceSummaryWidget({
    super.key,
    required this.attendanceList,
    this.dutyLeaveCountsAsPresent = true,
    this.onTargetChanged,
    this.highlightSubject,
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
  final GlobalKey _highlightKey = GlobalKey();
  String? _ensuredHighlight;

  bool _matchesHighlight(CourseAttendance item) {
    final query = widget.highlightSubject?.trim().toLowerCase();
    if (query == null || query.isEmpty) return false;
    return item.courseName.toLowerCase().contains(query) ||
        query.contains(item.courseName.toLowerCase()) ||
        item.courseId.toLowerCase() == query;
  }

  void _ensureHighlightVisible() {
    final target = widget.highlightSubject;
    if (target == null || widget.attendanceList.isEmpty) return;
    if (_ensuredHighlight == target) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _highlightKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.25,
        );
      }
      _ensuredHighlight = target;
    });
  }

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
    _ensureHighlightVisible();

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
        if (widget.attendanceList.isNotEmpty)
          _buildOverallCard(theme, targetPct),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.attendanceList.length,
          itemBuilder: (context, index) {
            final item = widget.attendanceList[index];
            final isHighlight = _matchesHighlight(item);
            return Padding(
              key: isHighlight ? _highlightKey : null,
              padding: EdgeInsets.zero,
              child: _AttendanceCard(
                attendance: item,
                dutyLeaveCountsAsPresent: widget.dutyLeaveCountsAsPresent,
                highlighted: isHighlight,
              ),
            );
          },
        ),
      ],
    );
  }

  ({int attended, int total, double pct}) _overallStats(bool dutyLeave) {
    int attended = 0;
    int total = 0;
    for (final item in widget.attendanceList) {
      total += dutyLeave
          ? item.classesAttended + item.classesOnDutyLeave + item.classesAbsent
          : item.classesAttended + item.classesAbsent;
      attended += dutyLeave
          ? item.classesAttended + item.classesOnDutyLeave
          : item.classesAttended;
    }
    return (attended: attended, total: total, pct: total == 0 ? 1.0 : attended / total);
  }

  Widget _buildOverallCard(ThemeData theme, double targetPct) {
    final stats = _overallStats(widget.dutyLeaveCountsAsPresent);
    final pct = stats.pct;
    final criticalCount = widget.attendanceList
        .where((a) => a.calculatePercentage(dutyLeaveCountsAsPresent: widget.dutyLeaveCountsAsPresent) < a.requiredPercentage)
        .length;
    final safeSkips = widget.attendanceList.fold<int>(
      0,
      (sum, a) => sum + a.calculateSafeSkips(dutyLeaveCountsAsPresent: widget.dutyLeaveCountsAsPresent),
    );

    final isDark = theme.brightness == Brightness.dark;
    final Color statusColor;
    final String warningLine;
    if (criticalCount > 0 || pct < targetPct) {
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      warningLine = criticalCount > 0
          ? '$criticalCount subject${criticalCount == 1 ? '' : 's'} below target'
          : 'Below your ${((targetPct) * 100).round()}% target';
    } else {
      statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      warningLine = 'On track across all subjects';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: statusColor,
                    backgroundColor: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERALL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.attended} of ${stats.total} classes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<bool>(
                  valueListenable: SafeWordService.unlocked,
                  builder: (context, unlocked, _) {
                    final String line;
                    if (criticalCount > 0 || pct < targetPct) {
                      line = warningLine;
                    } else if (unlocked && safeSkips > 0) {
                      line =
                          'On track · $safeSkips skippable class${safeSkips == 1 ? '' : 'es'} left';
                    } else {
                      line = 'On track across all subjects';
                    }
                    return Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final CourseAttendance attendance;
  final bool dutyLeaveCountsAsPresent;
  final bool highlighted;

  const _AttendanceCard({
    required this.attendance,
    required this.dutyLeaveCountsAsPresent,
    this.highlighted = false,
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

    Widget card = Card(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              attendance.courseName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (attendance.courseId.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme
                                    .colorScheme.surfaceContainerHighest
                                    .withAlpha(140),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                attendance.courseId.trim(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                      ValueListenableBuilder<bool>(
                        valueListenable: SafeWordService.unlocked,
                        builder: (context, unlocked, _) {
                          final showHint = unlocked || !isSafe;
                          return showHint
                              ? Text(
                                  hintText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withAlpha(70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (attendance.requiredPercentage * barWidth)
                          .clamp(2.0, barWidth - 2.0),
                      child: Container(
                        width: 2,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    if (!highlighted) return card;

    return _GlowPulse(child: card);
  }
}

class _GlowPulse extends StatefulWidget {
  final Widget child;

  const _GlowPulse({required this.child});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(140), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((60 + 70 * t).round()),
                blurRadius: 14 + 6 * t,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.child,
          ),
        );
      },
    );
  }
}
