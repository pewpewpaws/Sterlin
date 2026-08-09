import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger_service.dart';

/// Schedules background refresh of widget + Etlab data.
///
/// Scheduling model:
/// - After every successful manual fetch, a [OneTimeWorkRequest] is enqueued
///   to run at `last_manual_refresh + 1 hour`. This is the primary trigger.
/// - A [PeriodicWorkRequest] every 1h is also registered as a safety net
///   in case the OS drops the one-time job (Doze, app force-stop, etc.).
///
/// The worker is the same `WidgetRefreshWorker` registered in `main.dart`
/// `callbackDispatcher`, which calls `EtlabApiService.fetchAllData()`.
class BackgroundService {
  static const String _widgetRefreshTask = 'widget_refresh_task';
  static const String _oneTimeUniqueName = 'widget_refresh_one_time';
  static const String _periodicUniqueName = 'widget_refresh_periodic';

  /// Recompute the next refresh deadline and (re)schedule a one-time job.
  /// Called after every successful manual refresh in the app.
  static Future<void> scheduleNextRefresh() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastIso = prefs.getString('last_updated');
      final now = DateTime.now();

      DateTime deadline;
      if (lastIso != null && lastIso.isNotEmpty) {
        try {
          final last = DateTime.parse(lastIso);
          deadline = last.add(const Duration(hours: 1));
        } catch (_) {
          deadline = now.add(const Duration(hours: 1));
        }
      } else {
        deadline = now.add(const Duration(hours: 1));
      }

      // Don't run in the past — give it at least 60s so we don't hammer the API
      final delay = deadline.isAfter(now)
          ? deadline.difference(now)
          : const Duration(seconds: 60);

      // Cancel previous one-time job before scheduling a new one (avoid pile-up)
      try {
        await Workmanager().cancelByUniqueName(_oneTimeUniqueName);
      } catch (_) {}

      await Workmanager().registerOneOffTask(
        _oneTimeUniqueName,
        _widgetRefreshTask,
        initialDelay: delay,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      // Safety net: ensure the periodic worker is registered
      await _ensurePeriodicRegistered();

      AppLoggerService().log(
        'Scheduled next widget refresh in '
        '${delay.inMinutes}m ${delay.inSeconds % 60}s',
        category: 'BG_TASK',
      );
    } catch (e) {
      AppLoggerService().log(
        'Failed to schedule widget refresh: $e',
        category: 'ERROR',
      );
    }
  }

  static Future<void> _ensurePeriodicRegistered() async {
    try {
      await Workmanager().registerPeriodicTask(
        _periodicUniqueName,
        _widgetRefreshTask,
        frequency: const Duration(hours: 1),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      AppLoggerService().log(
        'Failed to register periodic refresh: $e',
        category: 'ERROR',
      );
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
      await Workmanager().cancelByUniqueName(_oneTimeUniqueName);
      await Workmanager().cancelByUniqueName(_periodicUniqueName);
      AppLoggerService().log('Cancelled all background refresh jobs', category: 'BG_TASK');
    } catch (e) {
      AppLoggerService().log('cancelAll error: $e', category: 'ERROR');
    }
  }

  /// Backwards-compatible alias — kept so any existing callers don't break.
  @Deprecated('Use scheduleNextRefresh() instead')
  static Future<void> scheduleDaily8AmTask() => scheduleNextRefresh();

  /// Backwards-compatible constant for the daily task name. The worker
  /// dispatcher in main.dart also listens to [_widgetRefreshTask], so this
  /// is no longer needed, but is kept to avoid breaking imports.
  static const String dailyFetchTask = _widgetRefreshTask;
}
