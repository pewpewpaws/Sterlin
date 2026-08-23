import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/dashboard_data.dart';
import 'background_service.dart';
import 'home_widget_service.dart';
import 'notifications_service.dart';

class EtlabApiService {
  static final EtlabApiService _instance = EtlabApiService._internal();
  factory EtlabApiService() => _instance;
  EtlabApiService._internal();

  static const String _keySubdomain = 'etlab_subdomain';
  static const String _keyUsername = 'etlab_username';
  static const String _keyAccessToken = 'etlab_access_token';
  static const String _keyProfileData = 'etlab_profile_data';
  static const String _keyAttendanceData = 'etlab_attendance_data';
  static const String _keyTeachersData = 'etlab_teachers_data';
  static const String _keyTeachersFetchedAt = 'etlab_teachers_fetched_at';
  static const String _keySemesterData = 'etlab_semester_data';
  static const String _keyTargetAttendancePct = 'etlab_target_attendance_pct';
  static const String _keyIsLoggedIn = 'etlab_is_logged_in';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _subdomain = 'sctce';
  String? _accessToken;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _teachersData;
  DateTime? _teachersFetchedAt;
  List<dynamic>? _semesterListData;
  double _targetAttendancePct = 0.75;
  final Map<String, Map<String, dynamic>> _monthMemoryCache = {};

  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  String get subdomain => _subdomain;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get profileData => _profileData;
  Map<String, dynamic>? get attendanceData => _attendanceData;
  Map<String, dynamic>? get teachersData => _teachersData;

  static const Duration teachersCacheTtl = Duration(days: 14);

  bool get teachersCacheFresh =>
      _teachersData != null &&
      _teachersFetchedAt != null &&
      DateTime.now().difference(_teachersFetchedAt!) < teachersCacheTtl;
  List<dynamic>? get semesterListData => _semesterListData;
  double get targetAttendancePct => _targetAttendancePct;

  Future<void> setTargetAttendancePct(double pct) async {
    _targetAttendancePct = pct < 0.75 ? 0.75 : pct;
    debugPrint('[API] setTargetAttendancePct(pct: $_targetAttendancePct)');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTargetAttendancePct, _targetAttendancePct);
    } catch (_) {}
  }

  String get baseUrl {
    final url = 'https://$_subdomain.etlab.in/androidapp';
    if (!url.startsWith('https://')) {
      throw Exception('Insecure URL blocked: $url');
    }
    return url;
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      final token = _accessToken!.startsWith('Bearer ')
          ? _accessToken!
          : 'Bearer $_accessToken';
      headers['Authorization'] = token;
    }
    return headers;
  }

  /// Initialize session from local data storage on app startup.
  Future<bool> initSession() async {
    debugPrint('[SESSION] initSession()');
    try {
      final prefs = await SharedPreferences.getInstance();
      _subdomain = prefs.getString(_keySubdomain) ?? 'sctce';
      _accessToken = await _secureStorage.read(key: _keyAccessToken);

      // Cleanup legacy shared prefs token if it exists
      if (prefs.containsKey(_keyAccessToken)) {
        await prefs.remove(_keyAccessToken);
      }
      // Sync the logged-in flag — covers upgrades from older app versions
      // where the flag wasn't written but a valid token may still exist.
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await prefs.setBool(_keyIsLoggedIn, true);
      } else {
        await prefs.remove(_keyIsLoggedIn);
      }
      final savedPct = prefs.getDouble(_keyTargetAttendancePct) ?? 0.75;
      _targetAttendancePct = savedPct < 0.75 ? 0.75 : savedPct;

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

      if (isLoggedIn) {
        try {
          final timetable = DashboardDataMapper.parseTimetableFromProfile(
            _profileData,
            subjectsData: _attendanceData,
            teachersData: _teachersData,
          );
          final attendance = DashboardDataMapper.parseAttendanceFromSubjects(
            _attendanceData ?? _profileData,
          );
          HomeWidgetService.updateHomeScreenWidget(
            timetable: timetable,
            attendance: attendance,
            profileData: _profileData,
            attendanceData: _attendanceData,
            teachersData: _teachersData,
          );
        } catch (_) {}

        // Token is present, refresh fresh data in background
        fetchAllData().catchError((_) {});
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _saveSessionData({String? username}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySubdomain, _subdomain);
      if (_accessToken != null) {
        await _secureStorage.write(key: _keyAccessToken, value: _accessToken!);
        await prefs.setBool(_keyIsLoggedIn, true);
      }
      if (username != null) {
        await prefs.setString(_keyUsername, username);
      }
      if (_profileData != null) {
        await prefs.setString(_keyProfileData, jsonEncode(_profileData));
      }
      if (_attendanceData != null) {
        await prefs.setString(_keyAttendanceData, jsonEncode(_attendanceData));
      }
      if (_teachersData != null) {
        await prefs.setString(_keyTeachersData, jsonEncode(_teachersData));
        if (_teachersFetchedAt != null) {
          await prefs.setInt(
            _keyTeachersFetchedAt,
            _teachersFetchedAt!.millisecondsSinceEpoch,
          );
        }
      }
      if (_semesterListData != null) {
        await prefs.setString(_keySemesterData, jsonEncode(_semesterListData));
      }
    } catch (_) {}
  }

  Future<bool> login({
    String subdomain = 'sctce',
    required String username,
    required String password,
    String hostelId = '0',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString(_keyUsername);
      if (savedUsername != null && savedUsername.isNotEmpty && savedUsername != username.trim()) {
        debugPrint('[SESSION] Different user logging in, purging old data...');
        await _purgeAllUserData();
      }
    } catch (_) {}

    _subdomain = subdomain.trim().isEmpty ? 'sctce' : subdomain.trim();
    debugPrint('[API] login(subdomain: "$_subdomain", username: "${username.trim()}", hostelId: "${hostelId.trim()}")');
    final url = Uri.parse('$baseUrl/app/login');

    final payload = {
      'username': username.trim(),
      'password': password,
      'hostel': hostelId.trim().isEmpty ? '0' : hostelId.trim(),
    };

    try {
      // 1. Try JSON POST request
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic>? data;
      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (_) {}

      // 2. Fallback to form-urlencoded if JSON fails or returns login=false
      if (response.statusCode != 200 ||
          data == null ||
          data['login'] == false) {
        final formResponse = await http.post(
          url,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: payload,
        ).timeout(const Duration(seconds: 15));

        if (formResponse.statusCode == 200 && formResponse.body.isNotEmpty) {
          try {
            final formData =
                jsonDecode(formResponse.body) as Map<String, dynamic>?;
            if (formData != null && formData['login'] != false) {
              response = formResponse;
              data = formData;
            }
          } catch (_) {}
        }
      }

      if (data != null && (data['login'] != false && data['status'] != '0')) {
        // Extract token if provided
        final token =
            data['access_token'] ??
            data['token'] ??
            (data['data'] is Map ? data['data']['access_token'] : null);

        if (token != null && token.toString().isNotEmpty) {
          _accessToken = token.toString();
        } else {
          // If server responds with valid login status without token, set session token
          _accessToken =
              'etlab_session_${username}_${DateTime.now().millisecondsSinceEpoch}';
        }

        _profileData = data;
        debugPrint('[API] login(username: "${username.trim()}", status: "success")');

        // Save session token & profile locally
        await _saveSessionData(username: username);

        // Fetch remaining endpoints in background
        await fetchAllData();
        return true;
      } else {
        debugPrint('[API] login(username: "${username.trim()}", status: "failed")');
        return false;
      }
    } on TimeoutException {
      debugPrint('[ERROR] login(username: "${username.trim()}", status: "timeout")');
      throw Exception('Connection timed out. Please try again.');
    } catch (e) {
      debugPrint('[ERROR] login(username: "${username.trim()}", status: "error", error: "$e")');
      throw Exception('Login failed. Check connection.');
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    debugPrint('[API] fetchProfile()');
    final url = Uri.parse('$baseUrl/app/profile');
    try {
      final response = await http.post(url, headers: _authHeaders).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _profileData = data;
          await _saveSessionData();
          return data;
        }
      }
    } catch (_) {
      rethrow;
    }
    return _profileData;
  }

  Future<Map<String, dynamic>?> fetchAttendanceBySubject({String? semester}) async {
    debugPrint('[API] fetchAttendanceBySubject(semester: "${semester ?? ""}")');
    final url = Uri.parse('$baseUrl/app/attendancebysubject');
    try {
      final bodyMap = (semester != null && semester.isNotEmpty)
          ? {'sem_id': semester, 'semester': semester}
          : <String, String>{};
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (semester == null || semester.isEmpty) {
            _attendanceData = data;
            await _saveSessionData();
          }
          return data;
        }
      }
    } catch (_) {
      rethrow;
    }
    return (semester == null || semester.isEmpty) ? _attendanceData : null;
  }

  Future<Map<String, dynamic>?> fetchTeachers() async {
    debugPrint('[API] fetchTeachers()');
    final url = Uri.parse('$baseUrl/app/teachers');
    try {
      final response = await http.post(url, headers: _authHeaders).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _teachersData = data;
          _teachersFetchedAt = DateTime.now();
          await _saveSessionData();
          return data;
        }
      }
    } catch (_) {
      rethrow;
    }
    return _teachersData;
  }

  Future<List<dynamic>?> fetchSemesterList() async {
    debugPrint('[API] fetchSemesterList()');
    final url = Uri.parse('$baseUrl/app/semesterlist');
    try {
      final response = await http.post(url, headers: _authHeaders).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List<dynamic>) {
          _semesterListData = data;
          await _saveSessionData();
          return data;
        } else if (data is Map<String, dynamic>) {
          final semList = data['semesters'] ?? data['data'] ?? data['semesterlist'] ?? data['semesters_list'];
          if (semList is List<dynamic>) {
            _semesterListData = semList;
            await _saveSessionData();
            return semList;
          }
        }
      }
    } catch (_) {
      rethrow;
    }
    return _semesterListData;
  }

  Future<Map<String, dynamic>?> fetchAttendanceByDayPeriod({
    required int month,
    required int year,
    String? semester,
  }) async {
    debugPrint('[API] fetchAttendanceByDayPeriod(month: $month, year: $year, semester: "${semester ?? ""}")');
    final url = Uri.parse('$baseUrl/app/attendancebydayperiod');
    final sem = semester ?? _profileData?['sem_id']?.toString() ?? '5';
    final payload = {
      'month': month.toString(),
      'semester': sem,
      'year': year.toString(),
    };
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          await cacheMonthAttendance(month, year, data, semester: semester);
          return data;
        }
      }
    } catch (_) {
      rethrow;
    }
    return null;
  }

  static const String _keyCalendarIndex = 'etlab_calendar_months_index';

  String _getMonthStorageKey(int month, int year, String? semester) {
    final semKey = (semester != null && semester.isNotEmpty)
        ? semester
        : (_profileData?['sem_id']?.toString() ?? 'default');
    return 'etlab_month_${year}_${month}_$semKey';
  }

  Map<String, dynamic>? getMemoryCachedMonth(int month, int year, {String? semester}) {
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

  Future<Map<String, dynamic>?> getCachedMonthAttendance(int month, int year, {String? semester}) async {
    debugPrint('[CACHE] getCachedMonthAttendance(month: $month, year: $year, semester: "${semester ?? ""}")');
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

  Future<void> cacheMonthAttendance(int month, int year, Map<String, dynamic> data, {String? semester}) async {
    final semKey = (semester != null && semester.isNotEmpty)
        ? semester
        : (_profileData?['sem_id']?.toString() ?? 'default');
    debugPrint('[CACHE] cacheMonthAttendance(month: $month, year: $year, semester: "$semKey")');
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthKey = '${year}_${month}_$semKey';
      final storageKey = 'etlab_month_$monthKey';

      _monthMemoryCache[monthKey] = data;
      await prefs.setString(storageKey, jsonEncode(data));

      final List<String> indexList = prefs.getStringList(_keyCalendarIndex) ?? [];
      final bool isFirstTimeForMonth = !indexList.contains(monthKey);

      if (isFirstTimeForMonth) {
        indexList.add(monthKey);
        await prefs.setStringList(_keyCalendarIndex, indexList);
        await NotificationsService().seedMonthBaseline(data);
      } else {
        await NotificationsService().runDiffAndNotify();
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
    debugPrint('[CACHE] getAllArchivedCalendarData()');
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

  Future<void> fetchAllData() async {
    debugPrint('[API] fetchAllData()');

    final now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    
    final List<Future> fetchTasks = [
      fetchProfile(),
      fetchAttendanceBySubject(),
      if (!teachersCacheFresh) fetchTeachers(),
      fetchSemesterList(),
      fetchAttendanceByDayPeriod(month: currentMonth, year: currentYear),
    ];

    int prevMonth1 = currentMonth - 1;
    int prevYear1 = currentYear;
    if (prevMonth1 < 1) {
      prevMonth1 += 12;
      prevYear1 -= 1;
    }

    int prevMonth2 = currentMonth - 2;
    int prevYear2 = currentYear;
    if (prevMonth2 < 1) {
      prevMonth2 += 12;
      prevYear2 -= 1;
    }

    fetchTasks.add(fetchAttendanceByDayPeriod(month: prevMonth1, year: prevYear1));
    fetchTasks.add(fetchAttendanceByDayPeriod(month: prevMonth2, year: prevYear2));

    await Future.wait(fetchTasks);

    try {
      final timetable = DashboardDataMapper.parseTimetableFromProfile(
        _profileData,
        subjectsData: _attendanceData,
        teachersData: _teachersData,
      );
      final attendance = DashboardDataMapper.parseAttendanceFromSubjects(
        _attendanceData ?? _profileData,
      );
      await HomeWidgetService.updateHomeScreenWidget(
        timetable: timetable,
        attendance: attendance,
        profileData: _profileData,
        attendanceData: _attendanceData,
        teachersData: _teachersData,
      );
    } catch (_) {}

    // Reschedule next background refresh — 1h after this manual fetch.
    // Silently no-ops if the user is logged out by the time this runs.
    if (isLoggedIn) {
      try {
        await BackgroundService.scheduleNextRefresh();
      } catch (_) {}
    }
  }

  Future<void> _purgeAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove known static keys
      await prefs.remove(_keySubdomain);
      await prefs.remove(_keyUsername);
      await _secureStorage.delete(key: _keyAccessToken);
      await prefs.remove(_keyProfileData);
      await prefs.remove(_keyAttendanceData);
      await prefs.remove(_keyTeachersData);
      await prefs.remove(_keyTeachersFetchedAt);
      await prefs.remove(_keySemesterData);
      await prefs.remove(_keyTargetAttendancePct);
      await prefs.remove(_keyCalendarIndex);
      await prefs.remove(_keyIsLoggedIn);

      // Remove dynamic caches (months, semesters, etc.)
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith('etlab_month_') || 
            key.startsWith('etlab_sem_attendance_')) {
          await prefs.remove(key);
        }
      }

      await NotificationsService().clearNotificationsData();
      await HomeWidgetService.clearWidgetData();
    } catch (_) {}
  }

  Future<void> logout() async {
    debugPrint('[SESSION] logout()');
    _accessToken = null;
    _profileData = null;
    _attendanceData = null;
    _teachersData = null;
    _teachersFetchedAt = null;
    _teachersFetchedAt = null;
    _semesterListData = null;
    _monthMemoryCache.clear();

    await _purgeAllUserData();
    await BackgroundService.cancelAll();
  }
}
