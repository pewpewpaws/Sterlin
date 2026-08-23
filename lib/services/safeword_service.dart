import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeWordService {
  SafeWordService._();

  static const String _key = 'safeword_unlocked';
  static const String code = 'SafeWord';

  static final ValueNotifier<bool> unlocked = ValueNotifier(false);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      unlocked.value = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  static Future<void> set(bool value) async {
    unlocked.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }

  static bool matches(String input) => input.trim() == code;
}
