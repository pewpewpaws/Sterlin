import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages all domain data fetched from the Etlab API, including
/// student profile, attendance snapshots, faculty directory, and calendar cache.
class EtlabDataStore {
  static final EtlabDataStore _instance = EtlabDataStore._internal();
  factory EtlabDataStore() => _instance;
  EtlabDataStore._internal();

  static const String _keyProfileData = 'etlab_profile_data';
  static const String _keyAttendanceData = 'etlab_attendance_data';
  static const String _keyTeachersData = 'etlab_teachers_data';
  static const String _keyTeachersFetchedAt = 'etlab_teachers_fetched_at';
  static const String _keySemesterData = 'etlab_semester_data';
  static const String _keyCalendarIndex = 'etlab_calendar_months_index';

  static const Duration teachersCacheTtl = Duration(days: 14);

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _teachersData;
  DateTime? _teachersFetchedAt;
  List<dynamic>? _semesterListData;
  final Map<String, Map<String, dynamic>> _monthMemoryCache = {};

  Map<String, dynamic>? get profileData => _profileData;
  Map<String, dynamic>? get attendanceData => _attendanceData;
  Map<String, dynamic>? get teachersData => _teachersData;
  DateTime? get teachersFetchedAt => _teachersFetchedAt;
  List<dynamic>? get semesterListData => _semesterListData;

  bool get teachersCacheFresh =>
      _teachersData != null &&
      _teachersFetchedAt != null &&
      DateTime.now().difference(_teachersFetchedAt!) < teachersCacheTtl;

  /// Loads cached server data and preloads calendar cache from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileJson = prefs.getString(_keyProfileData);
      if (profileJson != null && profileJson.isNotEmpty) {
        _profileData = jsonDecode(profileJson) as Map<String, dynamic>?;
      }

      final attendanceJson = prefs.getString(_keyAttendanceData);
      if (attendanceJson != null && attendanceJson.isNotEmpty) {
        _attendanceData = jsonDecode(attendanceJson) as Map<String, dynamic>?;
      }

      final teachersJson = prefs.getString(_keyTeachersData);
      if (teachersJson != null && teachersJson.isNotEmpty) {
        _teachersData = jsonDecode(teachersJson) as Map<String, dynamic>?;
      }
      final fetchedAt = prefs.getInt(_keyTeachersFetchedAt);
      if (fetchedAt != null) {
        _teachersFetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedAt);
      }

      final semesterJson = prefs.getString(_keySemesterData);
      if (semesterJson != null && semesterJson.isNotEmpty) {
        _semesterListData = jsonDecode(semesterJson) as List<dynamic>?;
      }

      await _preloadCalendarCache();
    } catch (e) {
      debugPrint('[EtlabDataStore] init error: $e');
    }
  }

  /// Persists student profile data.
  Future<void> saveProfile(Map<String, dynamic> data) async {
    _profileData = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfileData, jsonEncode(data));
    } catch (e) {
      debugPrint('[EtlabDataStore] saveProfile error: $e');
    }
  }

  /// Persists subject attendance data.
  Future<void> saveAttendance(Map<String, dynamic> data) async {
    _attendanceData = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAttendanceData, jsonEncode(data));
    } catch (e) {
      debugPrint('[EtlabDataStore] saveAttendance error: $e');
    }
  }

  /// Persists teachers data with a fresh timestamp.
  Future<void> saveTeachers(Map<String, dynamic> data) async {
    _teachersData = data;
    _teachersFetchedAt = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTeachersData, jsonEncode(data));
      await prefs.setInt(
        _keyTeachersFetchedAt,
        _teachersFetchedAt!.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[EtlabDataStore] saveTeachers error: $e');
    }
  }

  /// Persists semester list data.
  Future<void> saveSemesterList(List<dynamic> data) async {
    _semesterListData = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySemesterData, jsonEncode(data));
    } catch (e) {
      debugPrint('[EtlabDataStore] saveSemesterList error: $e');
    }
  }

  String _getMonthStorageKey(int month, int year, String? semester) {
    final semKey = (semester != null && semester.isNotEmpty)
        ? semester
        : (_profileData?['sem_id']?.toString() ?? 'default');
    return 'etlab_month_${year}_${month}_$semKey';
  }

  Map<String, dynamic>? getMemoryCachedMonth(
    int month,
    int year, {
    String? semester,
  }) {
    final semKey = (semester != null && semester.isNotEmpty)
        ? semester
        : (_profileData?['sem_id']?.toString() ?? 'default');
    final key = '${year}_${month}_$semKey';
    if (_monthMemoryCache.containsKey(key)) {
      return _monthMemoryCache[key];
    }
    final prefix = '${year}_${month}_';
    for (var k in _monthMemoryCache.keys) {
      if (k.startsWith(prefix)) return _monthMemoryCache[k];
    }
    return null;
  }

  Future<void> _preloadCalendarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexList = prefs.getStringList(_keyCalendarIndex) ?? [];
      for (final keyStr in indexList) {
        final jsonStr = prefs.getString('etlab_month_$keyStr');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final data = jsonDecode(jsonStr);
          if (data is Map<String, dynamic>) {
            _monthMemoryCache[keyStr] = data;
          }
        }
      }
    } catch (_) {}
  }

  /// Returns cached calendar day data for a given date (e.g. DateTime.now()).
  Map<String, dynamic>? getCachedDayData(DateTime date) {
    final y = date.year;
    final m = date.month;
    final dStr =
        '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (final monthData in _monthMemoryCache.values) {
      dynamic attends = monthData['attends'];
      if (attends == null && monthData['data'] is Map) {
        attends = monthData['data']['attends'];
      }
      if (attends is List) {
        for (final item in attends) {
          if (item is Map<String, dynamic> && item['date']?.toString() == dStr) {
            return item;
          }
        }
      }
    }
    return null;
  }

  /// Checks whether today (or a specific date) is marked as a holiday in the calendar data.
  ({bool isHoliday, String? reason}) getHolidayStatus({DateTime? date}) {
    final target = date ?? DateTime.now();
    final dayData = getCachedDayData(target);
    final isWeekend =
        target.weekday == DateTime.saturday || target.weekday == DateTime.sunday;

    if (dayData == null) {
      return (isHoliday: isWeekend, reason: isWeekend ? 'Weekend' : null);
    }

    final isHolidayFlag = dayData['holiday'] == true;
    final reason = dayData['holiday_reason']?.toString().trim();
    final periods = (dayData['periods'] as List?) ?? const [];
    final valid = periods.whereType<Map>().where((p) {
      final att = p['attendance']?.toString().trim().toLowerCase() ?? '';
      return att.isNotEmpty && att != 'na' && att != 'n/a';
    }).toList();

    final isHoliday = isHolidayFlag || (valid.isEmpty && isWeekend);
    return (
      isHoliday: isHoliday,
      reason: reason != null && reason.isNotEmpty
          ? reason
          : (isWeekend ? 'Weekend' : null),
    );
  }

  Future<Map<String, dynamic>?> getCachedMonthAttendance(
    int month,
    int year, {
    String? semester,
  }) async {
    debugPrint(
      '[EtlabDataStore] getCachedMonthAttendance(month: $month, year: $year, semester: "${semester ?? ""}")',
    );
    final mem = getMemoryCachedMonth(month, year, semester: semester);
    if (mem != null) return mem;

    try {
      final prefs = await SharedPreferences.getInstance();
      final targetKey = _getMonthStorageKey(month, year, semester);
      String? jsonStr = prefs.getString(targetKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        final prefix = 'etlab_month_${year}_${month}_';
        final matchingKeys = prefs.getKeys().where((k) => k.startsWith(prefix));
        if (matchingKeys.isNotEmpty) {
          jsonStr = prefs.getString(matchingKeys.first);
        }
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>?;
        if (data != null) {
          final semKey = (semester != null && semester.isNotEmpty)
              ? semester
              : (_profileData?['sem_id']?.toString() ?? 'default');
          _monthMemoryCache['${year}_${month}_$semKey'] = data;
        }
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheMonthAttendance(
    int month,
    int year,
    Map<String, dynamic> data, {
    String? semester,
    Future<void> Function(Map<String, dynamic> data)? onFirstTimeForMonth,
  }) async {
    final semKey = (semester != null && semester.isNotEmpty)
        ? semester
        : (_profileData?['sem_id']?.toString() ??
            _profileData?['student']?['sem_id']?.toString() ??
            '');
    debugPrint(
      '[EtlabDataStore] cacheMonthAttendance(month: $month, year: $year, semester: "$semKey")',
    );
    try {
      final attends = data['attends'];
      final prefs = await SharedPreferences.getInstance();
      final monthKey = '${year}_${month}_$semKey';
      final storageKey = 'etlab_month_$monthKey';

      // SAFEGUARD: Do not overwrite valid cached month data with empty data
      if (attends is List && attends.isEmpty) {
        final existing = prefs.getString(storageKey);
        if (existing != null && existing.isNotEmpty) {
          debugPrint(
            '[EtlabDataStore] Preserving existing cached month data for $monthKey (new data was empty)',
          );
          return;
        }
      }

      _monthMemoryCache[monthKey] = data;
      await prefs.setString(storageKey, jsonEncode(data));

      final List<String> indexList =
          prefs.getStringList(_keyCalendarIndex) ?? [];
      final bool isFirstTimeForMonth = !indexList.contains(monthKey);

      if (isFirstTimeForMonth) {
        indexList.add(monthKey);
        await prefs.setStringList(_keyCalendarIndex, indexList);
        if (onFirstTimeForMonth != null) {
          await onFirstTimeForMonth(data);
        }
      }
    } catch (_) {}
  }

  Future<List<String>> getStoredCalendarMonths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyCalendarIndex) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> getAllArchivedCalendarData() async {
    debugPrint('[EtlabDataStore] getAllArchivedCalendarData()');
    final Map<String, Map<String, dynamic>> allData = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexList = prefs.getStringList(_keyCalendarIndex) ?? [];
      for (final keyStr in indexList) {
        final storageKey = 'etlab_month_$keyStr';
        final jsonStr = prefs.getString(storageKey);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic> && decoded['attends'] is List) {
            for (var item in (decoded['attends'] as List<dynamic>)) {
              if (item is Map<String, dynamic> && item['date'] != null) {
                allData[item['date'].toString()] = item;
              }
            }
          }
        }
      }
    } catch (_) {}
    return allData;
  }

  /// Wipes all cached server responses and memory caches without affecting user credentials.
  Future<void> clearAllData() async {
    _profileData = null;
    _attendanceData = null;
    _teachersData = null;
    _teachersFetchedAt = null;
    _semesterListData = null;
    _monthMemoryCache.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProfileData);
      await prefs.remove(_keyAttendanceData);
      await prefs.remove(_keyTeachersData);
      await prefs.remove(_keyTeachersFetchedAt);
      await prefs.remove(_keySemesterData);
      await prefs.remove(_keyCalendarIndex);

      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith('etlab_month_') ||
            key.startsWith('etlab_sem_attendance_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[EtlabDataStore] clearAllData error: $e');
    }
  }
}
