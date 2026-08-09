import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogEntry {
  final DateTime timestamp;
  final String category;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
  });

  String formatTimestamp() {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class AppLoggerService {
  static final AppLoggerService _instance = AppLoggerService._internal();
  factory AppLoggerService() => _instance;
  AppLoggerService._internal();

  static const String _keyDebugEnabled = 'etlab_debug_logs_enabled';
  static const String _keyLogs = 'etlab_debug_logs_data';

  bool _isDebugModeEnabled = false;
  final List<LogEntry> _logs = [];
  final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier([]);

  bool get isDebugModeEnabled => _isDebugModeEnabled;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      _isDebugModeEnabled = prefs.getBool(_keyDebugEnabled) ?? false;
      
      final logsStr = prefs.getString(_keyLogs);
      if (logsStr != null) {
        final List<dynamic> decoded = jsonDecode(logsStr);
        _logs.clear();
        for (var item in decoded) {
          _logs.add(LogEntry(
            timestamp: DateTime.parse(item['t']),
            category: item['c'],
            message: item['m'],
          ));
        }
        logsNotifier.value = List.unmodifiable(_logs);
      }
    } catch (_) {}
  }

  Future<void> setDebugMode(bool enabled) async {
    _isDebugModeEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDebugEnabled, enabled);
    } catch (_) {}
    if (!enabled) {
      clearLogs();
    } else {
      log('setDebugMode(enabled: $enabled)', category: 'SYSTEM');
    }
  }

  void log(String message, {String category = 'INFO'}) {
    if (!_isDebugModeEnabled) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      category: category.toUpperCase(),
      message: message,
    );

    _logs.insert(0, entry);
    if (_logs.length > 500) {
      _logs.removeLast();
    }
    logsNotifier.value = List.unmodifiable(_logs);
    _persistLogs();
  }

  void _persistLogs() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        final logsJson = _logs.map((e) => {
          't': e.timestamp.toIso8601String(),
          'c': e.category,
          'm': e.message,
        }).toList();
        prefs.setString(_keyLogs, jsonEncode(logsJson));
      });
    } catch (_) {}
  }

  void clearLogs() {
    _logs.clear();
    logsNotifier.value = [];
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_keyLogs));
  }
}
