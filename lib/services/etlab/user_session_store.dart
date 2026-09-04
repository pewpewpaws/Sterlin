import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user-bound identity, credentials, tokens, and preferences.
class UserSessionStore {
  static final UserSessionStore _instance = UserSessionStore._internal();
  factory UserSessionStore() => _instance;
  UserSessionStore._internal();

  static const String _keySubdomain = 'etlab_subdomain';
  static const String _keyUsername = 'etlab_username';
  static const String _keyAccessToken = 'etlab_access_token';
  static const String _keyTargetAttendancePct = 'etlab_target_attendance_pct';
  static const String _keyIsLoggedIn = 'etlab_is_logged_in';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _subdomain = 'sctce';
  String? _username;
  String? _accessToken;
  double _targetAttendancePct = 0.75;

  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  String get subdomain => _subdomain;
  String? get username => _username;
  String? get accessToken => _accessToken;
  double get targetAttendancePct => _targetAttendancePct;

  /// Loads user session credentials and preferences from storage on startup.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSub = prefs.getString(_keySubdomain);
      if (savedSub == null ||
          savedSub.contains('://') ||
          savedSub.contains('/') ||
          savedSub.trim().isEmpty) {
        _subdomain = 'sctce';
        await prefs.setString(_keySubdomain, 'sctce');
      } else {
        _subdomain = savedSub.trim();
      }

      _username = prefs.getString(_keyUsername);

      _accessToken = await _secureStorage.read(key: _keyAccessToken);
      if (_accessToken != null && _accessToken!.startsWith('mock_')) {
        _accessToken = null;
        await _secureStorage.delete(key: _keyAccessToken);
      }

      // Cleanup legacy shared prefs token if it exists
      if (prefs.containsKey(_keyAccessToken)) {
        await prefs.remove(_keyAccessToken);
      }

      // Sync the logged-in flag — covers upgrades from older app versions
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await prefs.setBool(_keyIsLoggedIn, true);
      } else {
        await prefs.remove(_keyIsLoggedIn);
      }

      final savedPct = prefs.getDouble(_keyTargetAttendancePct) ?? 0.75;
      _targetAttendancePct = savedPct < 0.75 ? 0.75 : savedPct;
    } catch (e) {
      debugPrint('[UserSessionStore] init error: $e');
    }
  }

  /// Updates and persists the user's target attendance percentage.
  Future<void> setTargetAttendancePct(double pct) async {
    _targetAttendancePct = pct < 0.75 ? 0.75 : pct;
    debugPrint('[UserSessionStore] setTargetAttendancePct($_targetAttendancePct)');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTargetAttendancePct, _targetAttendancePct);
    } catch (e) {
      debugPrint('[UserSessionStore] setTargetAttendancePct error: $e');
    }
  }

  /// Saves user credentials after a successful login or session refresh.
  Future<void> saveCredentials({
    required String subdomain,
    required String username,
    String? accessToken,
  }) async {
    _subdomain = subdomain.trim().isEmpty ? 'sctce' : subdomain.trim();
    _username = username.trim();
    if (accessToken != null && accessToken.isNotEmpty) {
      _accessToken = accessToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySubdomain, _subdomain);
      await prefs.setString(_keyUsername, _username!);

      if (_accessToken != null) {
        await _secureStorage.write(key: _keyAccessToken, value: _accessToken!);
        await prefs.setBool(_keyIsLoggedIn, true);
      }
    } catch (e) {
      debugPrint('[UserSessionStore] saveCredentials error: $e');
    }
  }

  /// Clears user credentials, token, and session data.
  Future<void> clearSession() async {
    _accessToken = null;
    _username = null;
    _subdomain = 'sctce';
    _targetAttendancePct = 0.75;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySubdomain);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyTargetAttendancePct);
      await prefs.remove(_keyIsLoggedIn);
      await _secureStorage.delete(key: _keyAccessToken);
    } catch (e) {
      debugPrint('[UserSessionStore] clearSession error: $e');
    }
  }
}
