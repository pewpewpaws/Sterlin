import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger_service.dart';

/// Persistent notification that surfaces the user's next class on the
/// lock screen. Updated whenever [EtlabApiService.fetchAllData] finishes
/// successfully. Cancelled on logout or when the user disables the toggle.
class LockscreenNotificationService {
  static final LockscreenNotificationService _instance =
      LockscreenNotificationService._internal();
  factory LockscreenNotificationService() => _instance;
  LockscreenNotificationService._internal();

  static const int _notificationId = 4242;
  static const String _channelId = 'next_class_lockscreen';
  static const String _channelName = 'Next Class';
  static const String _channelDesc = 'Shows your next class on the lock screen';
  static const String _keyEnabled = 'lockscreen_notification_enabled';
  // Default disabled — the next-class lock-screen notification was
  // removed by user request. The flag remains for future opt-in.
  static const bool _defaultEnabled = false;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      await _plugin.initialize(settings: const InitializationSettings(android: android));
      _initialized = true;
    } catch (e) {
      AppLoggerService().log(
        'LockscreenNotificationService init failed: $e',
        category: 'NOTIF',
      );
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? _defaultEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    if (!enabled) {
      await cancel();
    } else {
      await updateFromCache();
    }
  }

  /// Read the first item from `timetable_json` (same source the 2x2 widget uses)
  /// and show/update the lock-screen notification.
  Future<void> updateFromCache() async {
    if (!kIsWeb &&
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    final enabled = await isEnabled();
    if (!enabled) {
      await cancel();
      return;
    }

    await _ensureInit();
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final timetableJsonStr =
          prefs.getString('timetable_json') ??
              prefs.getString('flutter.timetable_json');

      String courseName = 'No upcoming class';
      String timeStr = '';
      String room = '';
      String teacher = '';
      String detailLine = 'Open Sterlin to see your schedule';

      if (timetableJsonStr != null && timetableJsonStr.isNotEmpty) {
        try {
          final arr = jsonDecode(timetableJsonStr);
          if (arr is List && arr.isNotEmpty) {
            final first = arr.first as Map<String, dynamic>;
            courseName = (first['courseName']?.toString() ?? courseName)
                .split(' (')
                .first;
            timeStr = (first['timeStr']?.toString() ?? '')
                .split('|')
                .first
                .trim();
            final rawRoom = first['timeStr']?.toString() ?? '';
            final parts = rawRoom.split('|');
            if (parts.length > 1) room = parts.last.trim();
            teacher = first['teacherName']?.toString() ?? '';
          }
        } catch (_) {}
      }

      final title = timeStr.isEmpty
          ? courseName
          : '$courseName · $timeStr';

      if (room.isNotEmpty && teacher.isNotEmpty) {
        detailLine = 'Room $room · $teacher';
      } else if (room.isNotEmpty) {
        detailLine = 'Room $room';
      } else if (teacher.isNotEmpty) {
        detailLine = teacher;
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        ticker: 'Next class update',
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        category: AndroidNotificationCategory.event,
        styleInformation: BigTextStyleInformation(
          detailLine,
          contentTitle: title,
        ),
      );

      await _plugin.show(
        id: _notificationId,
        title: title,
        body: detailLine,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
      AppLoggerService().log(
        'Lock-screen notification updated: $title',
        category: 'NOTIF',
      );
    } catch (e) {
      AppLoggerService().log(
        'LockscreenNotificationService.updateFromCache error: $e',
        category: 'ERROR',
      );
    }
  }

  Future<void> cancel() async {
    if (!_initialized) {
      await _ensureInit();
    }
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _notificationId);
      AppLoggerService().log(
        'Lock-screen notification cancelled',
        category: 'NOTIF',
      );
    } catch (e) {
      AppLoggerService().log(
        'LockscreenNotificationService.cancel error: $e',
        category: 'ERROR',
      );
    }
  }
}
