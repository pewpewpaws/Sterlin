import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/dashboard_data.dart';
import 'background_service.dart';
import 'etlab/etlab_api_client.dart';
import 'etlab/etlab_data_store.dart';
import 'etlab/user_session_store.dart';
import 'home_widget_service.dart';
import 'notifications_service.dart';

/// Facade and orchestrator unifying user session storage, Etlab data caching,
/// and HTTP communications while providing a backward-compatible interface.
class EtlabApiService {
  static final EtlabApiService _instance = EtlabApiService._internal();
  factory EtlabApiService() => _instance;
  EtlabApiService._internal();

  final UserSessionStore _sessionStore = UserSessionStore();
  final EtlabDataStore _dataStore = EtlabDataStore();
  final EtlabApiClient _apiClient = EtlabApiClient();

  Future<void>? _activeFetchAllData;

  // Expose underlying stores if callers want domain-specific separation
  UserSessionStore get sessionStore => _sessionStore;
  EtlabDataStore get dataStore => _dataStore;
  EtlabApiClient get apiClient => _apiClient;

  // Backward-compatible getters
  bool get isLoggedIn => _sessionStore.isLoggedIn;
  String get subdomain => _sessionStore.subdomain;
  String? get accessToken => _sessionStore.accessToken;
  Map<String, dynamic>? get profileData => _dataStore.profileData;
  Map<String, dynamic>? get attendanceData => _dataStore.attendanceData;
  Map<String, dynamic>? get teachersData => _dataStore.teachersData;

  static const Duration teachersCacheTtl = EtlabDataStore.teachersCacheTtl;
  bool get teachersCacheFresh => _dataStore.teachersCacheFresh;
  List<dynamic>? get semesterListData => _dataStore.semesterListData;
  double get targetAttendancePct => _sessionStore.targetAttendancePct;

  String get baseUrl => EtlabApiClient.buildBaseUrl(_sessionStore.subdomain);

  Future<void> setTargetAttendancePct(double pct) =>
      _sessionStore.setTargetAttendancePct(pct);

  /// Initialize session from local storage on app startup.
  Future<bool> initSession() async {
    debugPrint('[SESSION] initSession()');
    try {
      await _sessionStore.init();
      await _dataStore.init();

      if (isLoggedIn) {
        try {
          final timetable = DashboardDataMapper.parseTimetableFromProfile(
            _dataStore.profileData,
            subjectsData: _dataStore.attendanceData,
            teachersData: _dataStore.teachersData,
          );
          final attendance = DashboardDataMapper.parseAttendanceFromSubjects(
            _dataStore.attendanceData ?? _dataStore.profileData,
          );
          HomeWidgetService.updateHomeScreenWidget(
            timetable: timetable,
            attendance: attendance,
            profileData: _dataStore.profileData,
            attendanceData: _dataStore.attendanceData,
            teachersData: _dataStore.teachersData,
          );
        } catch (_) {}

        // Token is present, refresh fresh data in background
        fetchAllData().catchError((_) {});
        return true;
      }
    } catch (e) {
      debugPrint('[SESSION] initSession error: $e');
    }

    return false;
  }

  Future<bool> login({
    String subdomain = 'sctce',
    required String username,
    required String password,
    String hostelId = '0',
  }) async {
    final cleanSub = subdomain.trim().isEmpty ? 'sctce' : subdomain.trim();
    final cleanUser = username.trim();

    // If a different user is logging in, purge previous student's cached data
    if (_sessionStore.username != null &&
        _sessionStore.username!.isNotEmpty &&
        _sessionStore.username != cleanUser) {
      debugPrint('[SESSION] Different user logging in, purging old data...');
      await _purgeAllUserData();
    }

    debugPrint(
      '[API] login(subdomain: "$cleanSub", username: "$cleanUser", hostelId: "${hostelId.trim()}")',
    );

    final currentBaseUrl = EtlabApiClient.buildBaseUrl(cleanSub);
    final data = await _apiClient.login(
      baseUrl: currentBaseUrl,
      username: cleanUser,
      password: password,
      hostelId: hostelId,
    );

    if (data != null) {
      final token =
          data['access_token'] ??
          data['token'] ??
          (data['data'] is Map ? data['data']['access_token'] : null);

      final resolvedToken = (token != null && token.toString().isNotEmpty)
          ? token.toString()
          : 'etlab_session_${cleanUser}_${DateTime.now().millisecondsSinceEpoch}';

      await _sessionStore.saveCredentials(
        subdomain: cleanSub,
        username: cleanUser,
        accessToken: resolvedToken,
      );

      await _dataStore.saveProfile(data);

      debugPrint('[API] login(username: "$cleanUser", status: "success")');

      // Fetch remaining endpoints in background
      await fetchAllData();
      await NotificationsService().seedAllHistoricalAbsences();
      return true;
    } else {
      debugPrint('[API] login(username: "$cleanUser", status: "failed")');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    debugPrint('[API] fetchProfile()');
    try {
      final data = await _apiClient.fetchProfile(
        baseUrl: baseUrl,
        token: _sessionStore.accessToken,
      );
      if (data != null) {
        await _dataStore.saveProfile(data);
        return data;
      }
    } catch (_) {
      rethrow;
    }
    return _dataStore.profileData;
  }

  Future<Map<String, dynamic>?> fetchAttendanceBySubject({
    String? semester,
  }) async {
    debugPrint('[API] fetchAttendanceBySubject(semester: "${semester ?? ""}")');
    try {
      final data = await _apiClient.fetchAttendanceBySubject(
        baseUrl: baseUrl,
        token: _sessionStore.accessToken,
        semester: semester,
      );
      if (data != null) {
        final currentSemId = _dataStore.profileData?['sem_id']?.toString();
        if (semester == null || semester.isEmpty || semester == currentSemId) {
          await _dataStore.saveAttendance(data);
        }
        return data;
      }
    } catch (_) {
      rethrow;
    }
    return _dataStore.attendanceData;
  }

  Future<Map<String, dynamic>?> fetchTeachers() async {
    debugPrint('[API] fetchTeachers()');
    try {
      final data = await _apiClient.fetchTeachers(
        baseUrl: baseUrl,
        token: _sessionStore.accessToken,
      );
      if (data != null) {
        await _dataStore.saveTeachers(data);
        return data;
      }
    } catch (_) {
      rethrow;
    }
    return _dataStore.teachersData;
  }

  Future<List<dynamic>?> fetchSemesterList() async {
    debugPrint('[API] fetchSemesterList()');
    try {
      final data = await _apiClient.fetchSemesterList(
        baseUrl: baseUrl,
        token: _sessionStore.accessToken,
      );
      if (data != null) {
        await _dataStore.saveSemesterList(data);
        return data;
      }
    } catch (_) {
      rethrow;
    }
    return _dataStore.semesterListData;
  }

  Future<Map<String, dynamic>?> fetchAttendanceByDayPeriod({
    required int month,
    required int year,
    String? semester,
  }) async {
    debugPrint(
      '[API] fetchAttendanceByDayPeriod(month: $month, year: $year, semester: "${semester ?? ""}")',
    );
    final sem = (semester != null && semester.isNotEmpty)
        ? semester
        : (_dataStore.profileData?['sem_id']?.toString() ??
            _dataStore.profileData?['student']?['sem_id']?.toString() ??
            '');

    try {
      final data = await _apiClient.fetchAttendanceByDayPeriod(
        baseUrl: baseUrl,
        token: _sessionStore.accessToken,
        month: month,
        year: year,
        semester: sem,
      );
      if (data != null) {
        await cacheMonthAttendance(month, year, data, semester: semester);
        return data;
      }
    } catch (_) {
      rethrow;
    }
    return null;
  }

  Map<String, dynamic>? getMemoryCachedMonth(
    int month,
    int year, {
    String? semester,
  }) =>
      _dataStore.getMemoryCachedMonth(month, year, semester: semester);

  Map<String, dynamic>? getCachedDayData(DateTime date) =>
      _dataStore.getCachedDayData(date);

  ({bool isHoliday, String? reason}) getHolidayStatus({DateTime? date}) =>
      _dataStore.getHolidayStatus(date: date);

  Future<Map<String, dynamic>?> getCachedMonthAttendance(
    int month,
    int year, {
    String? semester,
  }) =>
      _dataStore.getCachedMonthAttendance(month, year, semester: semester);

  Future<void> cacheMonthAttendance(
    int month,
    int year,
    Map<String, dynamic> data, {
    String? semester,
  }) =>
      _dataStore.cacheMonthAttendance(
        month,
        year,
        data,
        semester: semester,
        onFirstTimeForMonth: (d) => NotificationsService().seedMonthBaseline(d),
      );

  Future<List<String>> getStoredCalendarMonths() =>
      _dataStore.getStoredCalendarMonths();

  Future<Map<String, Map<String, dynamic>>> getAllArchivedCalendarData() =>
      _dataStore.getAllArchivedCalendarData();

  Future<void> fetchAllData() {
    if (_activeFetchAllData != null) {
      debugPrint(
        '[API] fetchAllData() already in progress, deduplicating request',
      );
      return _activeFetchAllData!;
    }
    _activeFetchAllData = _performFetchAllData();
    return _activeFetchAllData!;
  }

  Future<void> _performFetchAllData() async {
    debugPrint('[API] fetchAllData()');
    try {
      // 1. Fetch Profile first so we have the student details and accurate sem_id
      try {
        await fetchProfile();
      } catch (e) {
        debugPrint('[API] fetchProfile notice: $e');
      }

      final semId = _dataStore.profileData?['sem_id']?.toString() ??
          _dataStore.profileData?['student']?['sem_id']?.toString() ??
          '';

      final List<Future> fetchTasks = [
        fetchAttendanceBySubject(semester: semId).catchError((e) {
          debugPrint('[API] fetchAttendanceBySubject notice: $e');
          return null;
        }),
        if (!teachersCacheFresh)
          fetchTeachers().catchError((e) {
            debugPrint('[API] fetchTeachers notice: $e');
            return null;
          }),
        fetchSemesterList().catchError((e) {
          debugPrint('[API] fetchSemesterList notice: $e');
          return null;
        }),
      ];

      final now = DateTime.now();
      int currentMonth = now.month;
      int currentYear = now.year;

      for (int offset = 0; offset < 4; offset++) {
        int targetMonth = currentMonth - offset;
        int targetYear = currentYear;
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear -= 1;
        }
        fetchTasks.add(
          fetchAttendanceByDayPeriod(
            month: targetMonth,
            year: targetYear,
            semester: semId,
          ).catchError((e) {
            debugPrint('[API] fetchAttendanceByDayPeriod notice: $e');
            return null;
          }),
        );
      }

      await Future.wait(fetchTasks);

      // Run diff and notify exactly once after the batch of months is cached
      try {
        await NotificationsService().runDiffAndNotify();
      } catch (_) {}

      try {
        final timetable = DashboardDataMapper.parseTimetableFromProfile(
          _dataStore.profileData,
          subjectsData: _dataStore.attendanceData,
          teachersData: _dataStore.teachersData,
        );
        final attendance = DashboardDataMapper.parseAttendanceFromSubjects(
          _dataStore.attendanceData ?? _dataStore.profileData,
        );
        await HomeWidgetService.updateHomeScreenWidget(
          timetable: timetable,
          attendance: attendance,
          profileData: _dataStore.profileData,
          attendanceData: _dataStore.attendanceData,
          teachersData: _dataStore.teachersData,
        );
      } catch (_) {}

      // Reschedule next background refresh — 1h after this manual fetch.
      if (isLoggedIn) {
        try {
          await BackgroundService.scheduleNextRefresh();
        } catch (_) {}
      }
    } finally {
      _activeFetchAllData = null;
    }
  }

  Future<void> _purgeAllUserData() async {
    try {
      await _sessionStore.clearSession();
      await _dataStore.clearAllData();
      await NotificationsService().clearNotificationsData();
      await HomeWidgetService.clearWidgetData();
    } catch (_) {}
  }

  Future<void> logout() async {
    debugPrint('[SESSION] logout()');
    _activeFetchAllData = null;
    await _purgeAllUserData();
    await BackgroundService.cancelAll();
  }
}
