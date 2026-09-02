import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/etlab_api_service.dart';
import '../services/theme_service.dart';

/// Attendance calendar — month grid with outcome-colored days.
///
/// Design ported from the Sterlin UI redesign: summary chips, a soft rounded
/// grid card, directional slide between months, and a period-by-period day
/// sheet. Day-state logic follows the app's rule that a day only counts as
/// fully present/absent once every scheduled period is recorded.
class MonthCalendar extends StatefulWidget {
  final DateTime? targetDate;

  const MonthCalendar({super.key, this.targetDate});

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const int _monthsBack = 6;

  late DateTime _focusedMonth;
  DateTime? _highlightedDate;
  int _slideDir = 1;
  bool _refreshing = false;
  final Map<String, Map<String, Map<String, dynamic>>> _months = {};

  @override
  void initState() {
    super.initState();
    if (widget.targetDate != null) {
      _focusedMonth = DateTime(
        widget.targetDate!.year,
        widget.targetDate!.month,
        1,
      );
      _highlightedDate = DateTime(
        widget.targetDate!.year,
        widget.targetDate!.month,
        widget.targetDate!.day,
      );
    } else {
      final now = DateTime.now();
      _focusedMonth = DateTime(now.year, now.month, 1);
    }
    _loadMonth(_focusedMonth);
  }

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetDate != oldWidget.targetDate && widget.targetDate != null) {
      setState(() {
        _focusedMonth = DateTime(
          widget.targetDate!.year,
          widget.targetDate!.month,
          1,
        );
        _highlightedDate = DateTime(
          widget.targetDate!.year,
          widget.targetDate!.month,
          widget.targetDate!.day,
        );
      });
      _loadMonth(_focusedMonth);
    }
  }

  void _clearHighlight() {
    if (_highlightedDate != null) {
      setState(() {
        _highlightedDate = null;
      });
    }
  }

  Map<String, Map<String, dynamic>> _parse(Map<String, dynamic>? res) {
    final map = <String, Map<String, dynamic>>{};
    if (res != null && res['attends'] is List) {
      for (var item in (res['attends'] as List)) {
        if (item is Map<String, dynamic> && item['date'] != null) {
          map[item['date'].toString()] = item;
        }
      }
    }
    return map;
  }

  Future<void> _loadMonth(DateTime month) async {
    final key = '${month.year}_${month.month}';
    final api = EtlabApiService();

    if (!_months.containsKey(key)) {
      final mem = api.getMemoryCachedMonth(month.month, month.year);
      if (mem != null) _months[key] = _parse(mem);
      if (!_months.containsKey(key)) {
        final cached = await api.getCachedMonthAttendance(
          month.month,
          month.year,
        );
        if (cached != null && mounted) {
          setState(() => _months[key] = _parse(cached));
        }
      }
    }

    if (mounted) setState(() => _refreshing = true);
    try {
      final res = await api.fetchAttendanceByDayPeriod(
        month: month.month,
        year: month.year,
      );
      if (res != null && mounted) {
        setState(() => _months[key] = _parse(res));
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  void _changeMonth(int dir) {
    _clearHighlight();
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month - _monthsBack, 1);
    final latest = DateTime(now.year, now.month + 1, 1);
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + dir, 1);
    if (next.isBefore(earliest) || next.isAfter(latest)) return;

    HapticFeedback.selectionClick();
    setState(() {
      _slideDir = dir;
      _focusedMonth = next;
    });
    _loadMonth(next);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _StatusPalette.of(theme);
    final key = '${_focusedMonth.year}_${_focusedMonth.month}';
    final data = _months[key] ?? const {};

    // Month summary
    var presentDays = 0, absentDays = 0, dutyDays = 0;
    final y0 = _focusedMonth.year;
    final m0 = _focusedMonth.month;
    for (var d = 1; d <= DateTime(y0, m0 + 1, 0).day; d++) {
      final dd = data[_dateKey(DateTime(y0, m0, d))];
      if (dd == null) continue;
      final s = _dayState(DateTime(y0, m0, d), dd, palette);
      if (s.allAbsent) {
        absentDays++;
      } else if (s.allPresent && s.hasDuty) {
        dutyDays++;
      } else if (s.allPresent) {
        presentDays++;
      }
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _clearHighlight(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
        children: [
          // Summary strip
          Row(
            children: [
              _MonthStat(
                label: 'Full days',
                value: '$presentDays',
                color: palette.safe,
              ),
              const SizedBox(width: 8),
              _MonthStat(
                label: 'Missed',
                value: '$absentDays',
                color: palette.danger,
              ),
              const SizedBox(width: 8),
              _MonthStat(
                label: 'Duty leave',
                value: '$dutyDays',
                color: palette.duty,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Calendar card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .7),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: ThemeService.displayFontFamily,
                            ),
                          ),
                          if (_refreshing)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: SizedBox(
                                width: 46,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    minHeight: 2.4,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: .7,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_slideDir * .08, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                  ),
                  child: Column(
                    key: ValueKey(key),
                    children: [
                      Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      _grid(theme, palette, data),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(theme, 'Present', palette.safe),
                          const SizedBox(width: 14),
                          _legendDot(theme, 'Absent', palette.danger),
                          const SizedBox(width: 14),
                          _legendDot(theme, 'Duty leave', palette.duty),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _grid(
    ThemeData theme,
    _StatusPalette palette,
    Map<String, Map<String, dynamic>> data,
  ) {
    final y = _focusedMonth.year;
    final m = _focusedMonth.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final leadingEmpty = DateTime(y, m, 1).weekday % 7;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: .82,
      ),
      itemCount: leadingEmpty + daysInMonth,
      itemBuilder: (context, i) {
        if (i < leadingEmpty) return const SizedBox.shrink();
        final day = i - leadingEmpty + 1;
        final dt = DateTime(y, m, day);
        final dayData = data[_dateKey(dt)];
        final st = dayData == null ? null : _dayState(dt, dayData, palette);

        final isToday = today.year == y && today.month == m && today.day == day;
        final isHighlighted = _highlightedDate != null &&
            _highlightedDate!.year == y &&
            _highlightedDate!.month == m &&
            _highlightedDate!.day == day;
        final isFuture = dt.isAfter(today);

        final isWeekend = dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
        final isHoliday = st?.holiday == true || dayData?['holiday'] == true || (dayData == null && isWeekend);

        Color? bg;
        Color? fg;
        if (isHoliday) {
          bg = theme.colorScheme.surfaceContainerLowest;
          fg = palette.danger.withValues(alpha: isFuture ? .75 : .95);
        } else if (st == null) {
          bg = theme.colorScheme.surfaceContainerLowest;
          fg = theme.colorScheme.onSurfaceVariant.withValues(alpha: .45);
        } else if (!st.hasClasses || isFuture) {
          fg = theme.colorScheme.onSurfaceVariant.withValues(alpha: .75);
        } else if (st.allPresent) {
          bg = palette.safeContainer;
          fg = palette.safe;
        } else if (st.allAbsent) {
          bg = palette.dangerContainer;
          fg = palette.danger;
        } else {
          bg = Color.alphaBlend(
            palette.boundary.withValues(alpha: .12),
            theme.colorScheme.surfaceContainerLowest,
          );
          fg = theme.colorScheme.onSurfaceVariant;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _clearHighlight();
            if (dayData != null) {
              _showDaySheet(context, dt, dayData);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isHighlighted
                    ? theme.colorScheme.error
                    : (isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: .5)),
                width: isHighlighted ? 2.5 : (isToday ? 1.8 : 0.8),
              ),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.error.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: ThemeService.displayFontFamily,
                      color: fg,
                    ),
                  ),
                ),
                if (st != null && st.mixed && !isFuture)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final c in st.dots.take(3))
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.2),
                                child: Container(
                                  width: 4.5,
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (st.dots.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final c in st.dots.skip(3).take(3))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1.2),
                                    child: Container(
                                      width: 4.5,
                                      height: 4.5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                else if (st != null &&
                    st.hasClasses &&
                    st.allPresent &&
                    !st.hasDuty)
                  Icon(Icons.check_rounded, size: 10, color: fg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendDot(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // -- day state helpers ----------------------------------------------------

  ({
    bool holiday,
    bool hasClasses,
    bool allPresent,
    bool allAbsent,
    bool hasDuty,
    bool mixed,
    List<Color> dots,
  })
  _dayState(
    DateTime date,
    Map<String, dynamic>? dayData,
    _StatusPalette palette,
  ) {
    final periods = (dayData?['periods'] as List?) ?? const [];
    final valid = periods.whereType<Map>().where((p) {
      final att = p['attendance']?.toString().trim().toLowerCase() ?? '';
      return att.isNotEmpty && att != 'na' && att != 'n/a';
    }).toList();

    final weekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final holiday = dayData?['holiday'] == true || (valid.isEmpty && weekend);

    var allPresent = false, allAbsent = false, hasDuty = false;
    final dots = <Color>[];

    if (valid.isNotEmpty) {
      final scheduledCount = _scheduledPeriodCount(date);
      final allScheduledMarked = valid.length >= scheduledCount;

      allPresent =
          valid.every((p) {
            final a = p['attendance'].toString().trim().toLowerCase();
            return a == 'present';
          }) &&
          allScheduledMarked;
      allAbsent =
          valid.every(
            (p) => p['attendance'].toString().trim().toLowerCase() == 'absent',
          ) &&
          allScheduledMarked;
      hasDuty = valid.any((p) {
        final a = p['attendance'].toString().trim().toLowerCase();
        return a == 'dutyleave' || a == 'duty leave';
      });

      for (final p in valid) {
        final a = p['attendance'].toString().trim().toLowerCase();
        if (a == 'present') dots.add(palette.safe);
        if (a == 'absent') dots.add(palette.danger);
        if (a == 'dutyleave' || a == 'duty leave') dots.add(palette.duty);
      }
    }

    return (
      holiday: holiday,
      hasClasses: valid.isNotEmpty,
      allPresent: allPresent && !hasDuty,
      allAbsent: allAbsent,
      hasDuty: hasDuty,
      mixed: valid.isNotEmpty && !allPresent && !allAbsent,
      dots: dots,
    );
  }

  /// Number of periods the timetable schedules on [date]; a day is only
  /// "complete" once that many periods have been recorded.
  int _scheduledPeriodCount(DateTime dt) {
    final profile = EtlabApiService().profileData;
    final dayIndex = dt.weekday - 1; // Mon=0 .. Sun=6
    if (profile != null && profile['timetable'] is List) {
      final rawTt = profile['timetable'] as List<dynamic>;
      if (dayIndex >= 0 && dayIndex < rawTt.length && rawTt[dayIndex] is List) {
        final dayPeriods = rawTt[dayIndex] as List<dynamic>;
        int count = 0;
        for (var p in dayPeriods) {
          if (p is Map) {
            final subj = (p['subject']?.toString() ?? '').trim().toUpperCase();
            final type = p['type']?.toString().toUpperCase() ?? 'TH';
            if (subj.isNotEmpty && subj != 'FREE PERIOD' && type != 'FR') {
              count++;
            }
          }
        }
        if (count > 0) return count;
      }
    }
    return 6; // default daily periods
  }

  void _showDaySheet(
    BuildContext context,
    DateTime date,
    Map<String, dynamic> dayData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(date: date, dayData: dayData),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixed status palette (independent of accent color)
// ---------------------------------------------------------------------------

class _StatusPalette {
  final Color safe;
  final Color safeContainer;
  final Color boundary;
  final Color danger;
  final Color dangerContainer;
  final Color duty;

  const _StatusPalette({
    required this.safe,
    required this.safeContainer,
    required this.boundary,
    required this.danger,
    required this.dangerContainer,
    required this.duty,
  });

  static _StatusPalette of(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? const _StatusPalette(
          safe: Color(0xFF54DD88),
          safeContainer: Color(0xFF12301F),
          boundary: Color(0xFFF5BE45),
          danger: Color(0xFFFF7076),
          dangerContainer: Color(0xFF3A1518),
          duty: Color(0xFF53C3F7),
        )
      : const _StatusPalette(
          safe: Color(0xFF159A52),
          safeContainer: Color(0xFFE0F5E8),
          boundary: Color(0xFFC77F07),
          danger: Color(0xFFD93A3A),
          dangerContainer: Color(0xFFFDE4E4),
          duty: Color(0xFF0987C6),
        );
}

// ---------------------------------------------------------------------------
// Month stat chip
// ---------------------------------------------------------------------------

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: .1),
            theme.colorScheme.surfaceContainerLow,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: ThemeService.displayFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day detail sheet
// ---------------------------------------------------------------------------

class _DaySheet extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> dayData;

  const _DaySheet({required this.date, required this.dayData});

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _StatusPalette.of(theme);
    final periods = ((dayData['periods'] as List?) ?? [])
        .whereType<Map>()
        .where((p) {
          final att = p['attendance']?.toString().trim().toLowerCase() ?? '';
          return att.isNotEmpty && att != 'na' && att != 'n/a';
        })
        .toList();
    final isHoliday = dayData['holiday'] == true;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .35,
        maxChildSize: .88,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: .3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _weekdays[date.weekday - 1].toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_months[date.month - 1]} ${date.day}, ${date.year}',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (isHoliday)
                    _pill(context, 'Holiday', palette.boundary)
                  else if (periods.isNotEmpty)
                    _pill(
                      context,
                      '${periods.length} classes',
                      theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (isHoliday)
                _HolidayCard(
                  date: date,
                  reason: dayData['holiday_reason']?.toString(),
                )
              else if (periods.isEmpty)
                Text(
                  'No recorded classes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                for (final (i, p) in periods.indexed)
                  _PeriodRow(map: p, index: i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: .14),
          theme.colorScheme.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final Map map;
  final int index;

  const _PeriodRow({required this.map, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _StatusPalette.of(theme);
    final subject = map['subject']?.toString() ?? '—';
    final hour = map['hour'];
    final att = map['attendance']?.toString().trim().toLowerCase() ?? '';
    final topics = ((map['topic_cov'] as List?) ?? [])
        .map((e) => e.toString())
        .where((t) => t.trim().isNotEmpty)
        .toList();

    final (color, label, icon) = switch (att) {
      'present' => (palette.safe, 'Present', Icons.check_circle_rounded),
      'absent' => (palette.danger, 'Absent', Icons.cancel_rounded),
      'dutyleave' || 'duty leave' => (
        palette.duty,
        'Duty leave',
        Icons.flight_takeoff_rounded,
      ),
      _ => (
        theme.colorScheme.onSurfaceVariant,
        att.toUpperCase(),
        Icons.help_outline_rounded,
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 45).clamp(0, 240)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hour != null ? 'Period $hour' : '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (topics.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      topics.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  color.withValues(alpha: .14),
                  theme.colorScheme.surfaceContainerLow,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final DateTime date;
  final String? reason;

  const _HolidayCard({required this.date, this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _StatusPalette.of(theme);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday ? 'No classes today' : 'No classes on this day';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          palette.boundary.withValues(alpha: .1),
          theme.colorScheme.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.beach_access_rounded, color: palette.boundary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(reason!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
