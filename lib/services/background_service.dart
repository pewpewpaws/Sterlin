import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_data.dart';
import 'etlab_api_service.dart';

/// Schedules background refresh of widget + Etlab data.
class BackgroundService {
  static const String widgetRefreshTask = 'widget_refresh_task';
  static const String _periodicUniqueName = 'widget_refresh_periodic';

  static const Duration _fastRefresh = Duration(hours: 1);
  static const Duration _normalRefresh = Duration(hours: 5);

  /// 1h while classes are active/imminent today, otherwise 5h.
  static Duration get currentRefreshFrequency {
    try {
      final active = DashboardDataMapper.isClassActiveWindow(
        EtlabApiService().profileData,
      );
      return active ? _fastRefresh : _normalRefresh;
    } catch (_) {
      return _normalRefresh;
    }
  }

  /// Ensures the periodic worker is registered.
  /// Called after every successful manual refresh in the app.
  static Future<void> scheduleNextRefresh() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      await _ensurePeriodicRegistered(currentRefreshFrequency);
      debugPrint(
        '[BG_TASK] Scheduled periodic refresh '
        '(${currentRefreshFrequency.inHours}h)',
      );
    } catch (e) {
      debugPrint('[ERROR] Failed to schedule widget refresh: $e');
    }
  }

  static Future<void> _ensurePeriodicRegistered(Duration frequency) async {
    try {
      await Workmanager().registerPeriodicTask(
        _periodicUniqueName,
        widgetRefreshTask,
        frequency: frequency,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('[ERROR] Failed to register periodic refresh: $e');
    }
  }

  /// Cancel all background refresh work — called on logout.
  static Future<void> cancelAll() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await Workmanager().cancelByUniqueName(_periodicUniqueName);
      debugPrint('[BG_TASK] Cancelled all background refresh jobs');
    } catch (e) {
      debugPrint('[ERROR] cancelAll error: $e');
    }
  }
}
