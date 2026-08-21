import 'dart:async';
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

  Map<String, dynamic> toJson() => {
    't': timestamp.millisecondsSinceEpoch,
    'c': category,
    'm': message,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['t'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    ),
    category: json['c'] as String? ?? 'INFO',
    message: json['m'] as String? ?? '',
  );

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
  static const String _keyLogsData = 'etlab_debug_logs_data';

  static DebugPrintCallback? _originalDebugPrint;
  static bool _isHooked = false;

  bool _isDebugModeEnabled = true;
  final List<LogEntry> _logs = [];
  final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier([]);
  Timer? _saveTimer;

  bool get isDebugModeEnabled => _isDebugModeEnabled;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    _hookDebugPrint();
    await loadLogs();
  }

  void _hookDebugPrint() {
    if (_isHooked) return;
    _isHooked = true;
    _originalDebugPrint = debugPrint;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.isNotEmpty) {
        _instance._processLogMessage(message);
      }
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
    };
  }

  void _processLogMessage(String raw) {
    if (!_isDebugModeEnabled) return;

    final match = RegExp(r'^\[([A-Za-z0-9_\-]+)\]\s*(.*)$').firstMatch(raw);
    if (match != null) {
      final cat = match.group(1)!;
      final msg = match.group(2) ?? '';
      _addEntry(LogEntry(
        timestamp: DateTime.now(),
        category: cat.toUpperCase(),
        message: msg.isNotEmpty ? msg : raw,
      ));
    } else {
      _addEntry(LogEntry(
        timestamp: DateTime.now(),
        category: 'APP',
        message: raw,
      ));
    }
  }

  Future<void> loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDebugModeEnabled = prefs.getBool(_keyDebugEnabled) ?? true;
      final jsonStr = prefs.getString(_keyLogsData);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          _logs.clear();
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              _logs.add(LogEntry.fromJson(item));
            }
          }
          logsNotifier.value = List.unmodifiable(_logs);
        }
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
      log('Logging enabled', category: 'SYSTEM');
    }
  }

  void log(String message, {String category = 'INFO'}) {
    final upperCat = category.toUpperCase();
    if (_isDebugModeEnabled) {
      _addEntry(LogEntry(
        timestamp: DateTime.now(),
        category: upperCat,
        message: message,
      ));
    }
    _originalDebugPrint?.call('[$upperCat] $message');
  }

  void _addEntry(LogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > 300) {
      _logs.removeLast();
    }
    logsNotifier.value = List.unmodifiable(_logs);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _persistLogs();
    });
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _logs.take(200).map((e) => e.toJson()).toList();
      await prefs.setString(_keyLogsData, jsonEncode(jsonList));
    } catch (_) {}
  }

  void clearLogs() {
    _saveTimer?.cancel();
    _logs.clear();
    logsNotifier.value = [];
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyLogsData);
    }).catchError((_) {});
  }
}
