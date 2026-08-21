import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../widgets/attendance_summary.dart';
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
        appBar: AppBar(
          title: const Text('Overall Attendance'),
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
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'By Subject'),
              Tab(text: 'By Day'),
            ],
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: TabBarView(
              children: [
                // Tab 1: Subjectwise Attendance
                _buildSubjectwiseTab(theme),
                // Tab 2: Dynamic Attendance Calendar View
                _CalendarAttendanceView(isTabMode: widget.isTabMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarAttendanceView extends StatefulWidget {
  final bool isTabMode;
  const _CalendarAttendanceView({this.isTabMode = false});

  @override
  State<_CalendarAttendanceView> createState() =>
      _CalendarAttendanceViewState();
}

class _CalendarAttendanceViewState extends State<_CalendarAttendanceView> {
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

  // 6 months prior up to current month (covers a full semester)
  static const int _monthsBack = 6;

  late DateTime _focusedMonth;
  bool _isBackgroundRefreshing = false;
  final Map<String, Map<String, Map<String, dynamic>>> _allMonthsData = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);

    final key = '${_focusedMonth.year}_${_focusedMonth.month}';
    final api = EtlabApiService();
    final mem = api.getMemoryCachedMonth(
      _focusedMonth.month,
      _focusedMonth.year,
    );
    if (mem != null) {
      final parsed = _parseMonthData(mem);
      _allMonthsData[key] = parsed;
    }
    _fetchMonthData(_focusedMonth.month, _focusedMonth.year);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _parseMonthData(Map<String, dynamic>? res) {
    final Map<String, Map<String, dynamic>> parsedMap = {};
    if (res != null && res['attends'] is List) {
      for (var item in (res['attends'] as List<dynamic>)) {
        if (item is Map<String, dynamic> && item['date'] != null) {
          parsedMap[item['date'].toString()] = item;
        }
      }
    }
    return parsedMap;
  }

  Future<void> _fetchMonthData(int month, int year) async {
    final key = '${year}_$month';
    final api = EtlabApiService();

    if (!_allMonthsData.containsKey(key) || _allMonthsData[key]!.isEmpty) {
      final cached = await api.getCachedMonthAttendance(month, year);
      if (cached != null) {
        final cachedMap = _parseMonthData(cached);
        _allMonthsData[key] = cachedMap;
        if (mounted &&
            _focusedMonth.month == month &&
            _focusedMonth.year == year) {
          setState(() {});
        }
      }
    }

    if (mounted && _focusedMonth.month == month && _focusedMonth.year == year) {
      setState(() {
        _isBackgroundRefreshing = true;
      });
    }

    try {
      final res = await api.fetchAttendanceByDayPeriod(
        month: month,
        year: year,
      );

      if (res != null) {
        final freshMap = _parseMonthData(res);
        _allMonthsData[key] = freshMap;

        if (mounted &&
            _focusedMonth.month == month &&
            _focusedMonth.year == year) {
          setState(() {
            _isBackgroundRefreshing = false;
          });
        }
      } else {
        if (mounted &&
            _focusedMonth.month == month &&
            _focusedMonth.year == year) {
          setState(() {
            _isBackgroundRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted &&
          _focusedMonth.month == month &&
          _focusedMonth.year == year) {
        setState(() {
          _isBackgroundRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _changeMonth(int increment) {
    final now = DateTime.now();
    final earliestMonth = DateTime(now.year, now.month - _monthsBack, 1);
    final latestMonth = DateTime(now.year, now.month + 1, 1);

    final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment, 1);
    if (newMonth.isBefore(earliestMonth) || newMonth.isAfter(latestMonth)) return;

    final key = '${newMonth.year}_${newMonth.month}';
    final api = EtlabApiService();

    if (!_allMonthsData.containsKey(key) || _allMonthsData[key]!.isEmpty) {
      final mem = api.getMemoryCachedMonth(newMonth.month, newMonth.year);
      if (mem != null) {
        _allMonthsData[key] = _parseMonthData(mem);
      }
    }

    setState(() {
      _focusedMonth = newMonth;
      _isBackgroundRefreshing = true;
    });

    _fetchMonthData(newMonth.month, newMonth.year);
  }

  String _formatDateKey(DateTime dt) => dt.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = '${_focusedMonth.year}_${_focusedMonth.month}';
    final data = _allMonthsData[key] ?? const {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = constraints.maxHeight;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SingleChildScrollView(
            key: ValueKey<String>(key),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: _buildMonthTile(theme, _focusedMonth, data, maxH),
          ),
        );
      },
    );
  }

  int _getScheduledPeriodCount(DateTime dt) {
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

  /// One month's calendar tile. Header (month name + nav arrows) is at the
  /// top, then the days-of-week strip and the day grid below.
  Widget _buildMonthTile(
    ThemeData theme,
    DateTime month,
    Map<String, Map<String, dynamic>> data,
    double maxAvailableHeight,
  ) {
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final year = month.year;
    final m = month.month;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final firstWeekday = DateTime(year, m, 1).weekday; // Mon=1..Sun=7
    final leadingEmptySlots = firstWeekday % 7; // Sun=0, Mon=1...

    final now = DateTime.now();
    final isCurrentMonth = _focusedMonth.year == year && _focusedMonth.month == m;
    final earliestLimit = DateTime(now.year, now.month - _monthsBack, 1);
    final latestLimit = DateTime(now.year, now.month + 1, 1);

    final isLatestMonth = year > latestLimit.year || (year == latestLimit.year && m >= latestLimit.month);
    final isEarliestMonth = year < earliestLimit.year || (year == earliestLimit.year && m <= earliestLimit.month);

    final isDark = theme.brightness == Brightness.dark;
    final presentColor = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final absentColor = isDark
        ? const Color(0xFFF87171)
        : const Color(0xFFDC2626);
    final dutyLeaveColor = isDark
        ? const Color(0xFFFACC15)
        : const Color(0xFFEAB308);
    final dutyLeaveTextColor = isDark
        ? const Color(0xFFFDE047)
        : const Color(0xFF854D0E);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month Header Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: isEarliestMonth ? null : () => _changeMonth(-1),
                ),
                Row(
                  children: [
                    Text(
                      '${_monthNames[m - 1]} $year',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    if (isCurrentMonth && _isBackgroundRefreshing) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: isLatestMonth ? null : () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysOfWeek
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            // Spacious Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: leadingEmptySlots + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingEmptySlots) {
                  return const SizedBox.shrink();
                }

                final dayNum = index - leadingEmptySlots + 1;
                final currentDt = DateTime(year, m, dayNum);
                final dateKey = _formatDateKey(currentDt);
                final dayData = data[dateKey];

                final isToday =
                    DateTime.now().year == year &&
                    DateTime.now().month == m &&
                    DateTime.now().day == dayNum;

                Color? bgColor;
                Color textColor = theme.colorScheme.onSurface;
                final List<Widget> periodDots = [];

                final isWeekend =
                    currentDt.weekday == DateTime.saturday ||
                    currentDt.weekday == DateTime.sunday;
                final rawPeriods = dayData?['periods'] as List<dynamic>? ?? [];
                final validPeriods = rawPeriods.where((p) {
                  if (p is! Map) return false;
                  final att =
                      p['attendance']?.toString().trim().toLowerCase() ?? '';
                  return att != 'n/a' && att != 'na' && att.isNotEmpty;
                }).toList();

                final bool hasValidClasses = validPeriods.isNotEmpty;
                final isHoliday =
                    (dayData?['holiday'] == true) ||
                    (isWeekend && !hasValidClasses);

                final bool hasAbsent = validPeriods.any((p) {
                  final att =
                      p['attendance']?.toString().trim().toLowerCase() ?? '';
                  return att == 'absent';
                });

                final bool hasDutyLeave = validPeriods.any((p) {
                  final att =
                      p['attendance']?.toString().trim().toLowerCase() ?? '';
                  return att == 'dutyleave' || att == 'duty leave';
                });

                final scheduledCount = _getScheduledPeriodCount(currentDt);
                final bool allScheduledMarked = validPeriods.length >= scheduledCount;

                final bool allPresent =
                    hasValidClasses && allScheduledMarked && !hasAbsent && !hasDutyLeave;
                final bool allPresentWithDL =
                    hasValidClasses && allScheduledMarked && !hasAbsent && hasDutyLeave;
                final bool allAbsent = hasValidClasses &&
                    allScheduledMarked &&
                    validPeriods.every((p) {
                      final att = p['attendance']?.toString().trim().toLowerCase() ?? '';
                      return att == 'absent';
                    });

                if (isHoliday) {
                  bgColor = isDark
                      ? theme.colorScheme.surfaceContainerHighest.withAlpha(90)
                      : theme.colorScheme.surfaceContainerHighest.withAlpha(
                          120,
                        );
                  textColor = theme.colorScheme.onSurfaceVariant.withAlpha(140);
                } else if (hasValidClasses) {
                  if (allPresent) {
                    textColor = presentColor;
                  } else if (allAbsent) {
                    textColor = absentColor;
                  } else {
                    if (allPresentWithDL) {
                      textColor = dutyLeaveTextColor;
                    }

                    for (var p in validPeriods) {
                      final att =
                          p['attendance']?.toString().trim().toLowerCase() ??
                          '';
                      Color dotColor = Colors.transparent;

                      if (att == 'present') {
                        dotColor = presentColor;
                      } else if (att == 'absent') {
                        dotColor = absentColor;
                      } else if (att == 'dutyleave' || att == 'duty leave') {
                        dotColor = dutyLeaveColor;
                      }

                      if (dotColor != Colors.transparent) {
                        periodDots.add(
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                    }
                  }
                }

                if (isToday) {
                  bgColor = theme.colorScheme.primary.withAlpha(
                    isDark ? 55 : 30,
                  );
                  textColor = theme.colorScheme.primary;
                }

                Border? cellBorder;
                if (isToday) {
                  cellBorder = Border.all(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  );
                }

                return InkWell(
                  onTap: () {
                    _showDayDetailsSheet(context, currentDt, dayData);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: cellBorder,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 2.0,
                      horizontal: 1.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: textColor,
                              fontWeight:
                                  (isToday || allPresent || allPresentWithDL || allAbsent)
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (periodDots.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          SizedBox(
                            width:
                                22, // Forces wrap at 3 dots per line (5dp * 3 + 2dp * 2 = 19dp)
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 2.0,
                              runSpacing: 2.0,
                              children: periodDots,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            // Legend Row for Attendance Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Present', presentColor),
                const SizedBox(width: 14),
                _buildLegendItem('Absent', absentColor),
                const SizedBox(width: 14),
                _buildLegendItem(
                  'Duty Leave',
                  dutyLeaveColor,
                  textColor: dutyLeaveTextColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {Color? textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor ?? color,
          ),
        ),
      ],
    );
  }

  void _showDayDetailsSheet(
    BuildContext context,
    DateTime date,
    Map<String, dynamic>? dayData,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = "${_monthNames[date.month - 1]} ${date.day}, ${date.year}";
    final weekdayStr = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][date.weekday - 1];

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final allPeriods = dayData?['periods'] as List<dynamic>? ?? [];
    final validPeriods = allPeriods.where((p) {
      if (p is! Map<String, dynamic>) return false;
      final att = p['attendance']?.toString().trim().toLowerCase() ?? '';
      return att != 'n/a' && att != 'na' && att.isNotEmpty;
    }).toList();

    final isHoliday =
        (dayData?['holiday'] == true) || (isWeekend && validPeriods.isEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: validPeriods.length > 3 ? 0.65 : 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weekdayStr.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isHoliday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF713F12).withAlpha(150)
                                : const Color(0xFFFEF08A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Holiday',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFFDE047)
                                  : const Color(0xFF854D0E),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (validPeriods.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${validPeriods.length} Classes',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isHoliday)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.beach_access_outlined,
                              size: 28,
                              color: isDark
                                  ? const Color(0xFFFACC15)
                                  : const Color(0xFFCA8A04),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Holiday / No Classes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayData?['holiday_reason']?.toString() ??
                                        'No classes or sessions conducted on this day.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (validPeriods.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No class periods recorded for this date.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validPeriods.length,
                      itemBuilder: (context, idx) {
                        final p = validPeriods[idx] as Map<String, dynamic>;
                        final hour = p['hour'] ?? (idx + 1);
                        final subject =
                            p['subject']?.toString() ?? 'Free / Other';
                        final attendance = p['attendance']?.toString() ?? 'N/A';
                        final topics =
                            (p['topic_cov'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .where((e) => e.trim().isNotEmpty)
                                .toList() ??
                            [];

                        Color badgeBg =
                            theme.colorScheme.surfaceContainerHighest;
                        Color badgeFg = theme.colorScheme.onSurfaceVariant;
                        String attLabel = attendance.toUpperCase();

                        final attLower = attendance.toLowerCase();
                        if (attLower == 'present') {
                          badgeBg = isDark
                              ? const Color(0xFF14532D).withAlpha(180)
                              : const Color(0xFFDCFCE7);
                          badgeFg = isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF166534);
                        } else if (attLower == 'absent') {
                          badgeBg = isDark
                              ? const Color(0xFF7F1D1D).withAlpha(180)
                              : const Color(0xFFFEE2E2);
                          badgeFg = isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFF991B1B);
                        } else if (attLower == 'dutyleave' ||
                            attLower == 'duty leave') {
                          badgeBg = isDark
                              ? const Color(0xFF713F12).withAlpha(180)
                              : const Color(0xFFFEF08A);
                          badgeFg = isDark
                              ? const Color(0xFFFDE047)
                              : const Color(0xFF854D0E);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Period $hour',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        attLabel,
                                        style: TextStyle(
                                          color: badgeFg,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (subject.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    subject,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                  ),
                                ],
                                if (topics.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withAlpha(80),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notes_rounded,
                                          size: 14,
                                          color: theme.colorScheme.outline,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            topics.join(", "),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
