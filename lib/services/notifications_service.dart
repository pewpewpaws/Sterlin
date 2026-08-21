import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'etlab_api_service.dart';
import 'package:flutter/foundation.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Storage key for the baseline used to find diffs
  static const String _keyBaselineData = 'etlab_notifications_baseline';
  // Storage key for absences that have already triggered a notification
  static const String _keyNotifiedData = 'etlab_notifications_notified';
  // Storage key for user notification enabled toggle
  static const String _keyNotificationsEnabled = 'etlab_notifications_enabled';
  // Storage key for tracking if permission prompt dialog was shown
  static const String _keyHasPromptedPermission = 'etlab_notifications_has_prompted';

  Future<void> init() async {
    if (_initialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[ERROR] NotificationsService init failed: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    if (enabled) {
      await requestPermission();
    }
    debugPrint('[NOTIF] setNotificationsEnabled: $enabled');
  }

  Future<bool> hasPromptedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasPromptedPermission) ?? false;
  }

  Future<void> setPromptedPermission(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPromptedPermission, value);
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedAndroid = await androidImplementation?.requestNotificationsPermission();

      final iosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final bool? grantedIos = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (grantedAndroid ?? true) && (grantedIos ?? true);
    } catch (e) {
      debugPrint('[ERROR] requestPermission error: $e');
      return false;
    }
  }

  Future<void> showLocalNotification(String title, String body) async {
    if (!await areNotificationsEnabled()) return;
    await init();
    if (!_initialized) return;
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'absent_tracker_channel', 'Absent Tracker',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('[ERROR] showLocalNotification failed: $e');
    }
  }

  /// Calculates the skipped days by diffing the newly fetched calendar data against the stored baseline.
  Future<List<Map<String, dynamic>>> getNewAbsences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? baselineJson = prefs.getString(_keyBaselineData);
    final Map<String, dynamic> baseline = baselineJson != null ? jsonDecode(baselineJson) : {};

    final api = EtlabApiService();
    final Map<String, Map<String, dynamic>> currentData = await api.getAllArchivedCalendarData();
    
    List<Map<String, dynamic>> newAbsences = [];

    currentData.forEach((date, dayData) {
      if (dayData['periods'] is List) {
        for (var period in dayData['periods']) {
          if (period is! Map) continue;
          final String attendance = period['attendance']?.toString().toLowerCase() ?? '';
          
          // Strict check: Only look for absent markings
          if (attendance == 'absent') {
            final String subject = period['subject']?.toString() ?? 'Unknown';
            final String hour = period['hour']?.toString() ?? '';
            
            // Unique key for this specific absence event
            final String absenceKey = '${date}_${hour}_$subject';
            
            if (!baseline.containsKey(absenceKey)) {
              newAbsences.add({
                'date': date,
                'hour': hour,
                'subject': subject,
                'key': absenceKey,
              });
            }
          }
        }
      }
    });

    return newAbsences;
  }

  /// Called after a refresh to trigger push notifications for newly found absences.
  Future<void> runDiffAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notifiedJson = prefs.getString(_keyNotifiedData);
      final Map<String, dynamic> notified = notifiedJson != null ? jsonDecode(notifiedJson) : {};

      final newAbsences = await getNewAbsences();
      bool hasNewNotifs = false;

      for (var absence in newAbsences) {
        final key = absence['key'];
        if (notified.containsKey(key)) continue;

        final date = absence['date'];
        final subject = absence['subject'];
        final hour = absence['hour'];
        
        // Creative absent tracker notification
        await showLocalNotification(
          '🚨 Absence Detected',
          'You were marked absent for $subject\nDate: $date\nPeriod: Hour $hour',
        );

        notified[key] = true;
        hasNewNotifs = true;
      }

      if (hasNewNotifs) {
        await prefs.setString(_keyNotifiedData, jsonEncode(notified));
      }
      // Note: We don't mark them as read here. They stay "new" until the user views the Notifications screen.
    } catch (e) {
      debugPrint('[NOTIF] runDiffAndNotify error: $e');
    }
  }

  /// Called when a specific month's data is loaded for the VERY FIRST TIME.
  /// Seeds all existing absences in that month into notified/baseline state WITHOUT firing push notifications.
  Future<void> seedMonthBaseline(Map<String, dynamic> monthData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notifiedJson = prefs.getString(_keyNotifiedData);
      final Map<String, dynamic> notified = notifiedJson != null ? jsonDecode(notifiedJson) : {};

      final String? baselineJson = prefs.getString(_keyBaselineData);
      final Map<String, dynamic> baseline = baselineJson != null ? jsonDecode(baselineJson) : {};

      if (monthData['attends'] is List) {
        for (var item in (monthData['attends'] as List<dynamic>)) {
          if (item is Map && item['date'] != null && item['periods'] is List) {
            final date = item['date'].toString();
            for (var period in item['periods']) {
              if (period is! Map) continue;
              final String attendance = period['attendance']?.toString().toLowerCase() ?? '';
              if (attendance == 'absent') {
                final String subject = period['subject']?.toString() ?? 'Unknown';
                final String hour = period['hour']?.toString() ?? '';
                final String absenceKey = '${date}_${hour}_$subject';
                notified[absenceKey] = true;
                baseline[absenceKey] = true;
              }
            }
          }
        }
      }

      await prefs.setString(_keyNotifiedData, jsonEncode(notified));
      await prefs.setString(_keyBaselineData, jsonEncode(baseline));
      debugPrint('[NOTIF] Seeded month baseline for first-time month load');
    } catch (e) {
      debugPrint('[NOTIF] seedMonthBaseline error: $e');
    }
  }

  /// Called when the user opens the Notifications screen, moving new absences into the baseline.
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? baselineJson = prefs.getString(_keyBaselineData);
      final Map<String, dynamic> baseline = baselineJson != null ? jsonDecode(baselineJson) : {};

      final newAbsences = await getNewAbsences();
      for (var absence in newAbsences) {
        baseline[absence['key']] = true;
      }
      
      await prefs.setString(_keyBaselineData, jsonEncode(baseline));
    } catch (e) {
      debugPrint('[NOTIF] markAllAsRead error: $e');
    }
  }

  /// Called when the user manually dismisses a notification.
  Future<void> markAsRead(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? baselineJson = prefs.getString(_keyBaselineData);
      final Map<String, dynamic> baseline = baselineJson != null ? jsonDecode(baselineJson) : {};

      baseline[key] = true;
      
      await prefs.setString(_keyBaselineData, jsonEncode(baseline));
    } catch (e) {
      debugPrint('[NOTIF] markAsRead error: $e');
    }
  }

  /// Clears all notification baselines when logging out.
  Future<void> clearNotificationsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBaselineData);
      await prefs.remove(_keyNotifiedData);
      debugPrint('[NOTIF] Cleared all notification baselines');
    } catch (e) {
      debugPrint('[NOTIF] clearNotificationsData error: $e');
    }
  }
}
