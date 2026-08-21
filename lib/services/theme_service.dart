import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  // --- Singleton ---
  ThemeService._();
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;

  // --- Pref keys (app_theme_ prefix — never touched by _purgeAllUserData) ---
  static const _keyMode = 'app_theme_mode';
  static const _keySeedColor = 'app_theme_seed_color';
  static const _keyUseDynamic = 'app_theme_use_dynamic';

  static const Color _defaultSeedColor = Color(0xFF34C78A);

  static const presetColors = {
    'emerald': Color(0xFF34C78A),
    'indigo': Color(0xFF6366F1),
    'blue': Color(0xFF3B82F6),
    'teal': Color(0xFF14B8A6),
    'cyan': Color(0xFF06B6D4),
    'purple': Color(0xFFA855F7),
    'pink': Color(0xFFEC4899),
    'rose': Color(0xFFF43F5E),
    'orange': Color(0xFFF97316),
    'amber': Color(0xFFF59E0B),
    'lime': Color(0xFF84CC16),
    'slate': Color(0xFF64748B),
  };

  static const ThemeMode _defaultMode = ThemeMode.system;

  // --- State ---
  ThemeMode _themeMode = _defaultMode;
  Color _seedColor = _defaultSeedColor;
  bool _useDynamic = true;

  ColorScheme? _dynamicLight;
  ColorScheme? _dynamicDark;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamic => _useDynamic;
  ColorScheme? get dynamicLight => _dynamicLight;
  ColorScheme? get dynamicDark => _dynamicDark;

  // --- Button size constraints (mirrors existing main.dart) ---
  static final _buttonStyle = ButtonStyle(
    maximumSize: WidgetStateProperty.all(const Size(420, 52)),
    minimumSize: WidgetStateProperty.all(const Size(64, 44)),
  );

  ThemeData getLightTheme([ColorScheme? dynamicLight]) {
    final dyn = dynamicLight ?? _dynamicLight;
    final ColorScheme scheme;
    if (_useDynamic && dyn != null) {
      scheme = dyn;
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    );
  }

  ThemeData getDarkTheme([ColorScheme? dynamicDark]) {
    final dyn = dynamicDark ?? _dynamicDark;
    final ColorScheme scheme;
    if (_useDynamic && dyn != null) {
      scheme = dyn;
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    );
  }

  ThemeData get lightTheme => getLightTheme();
  ThemeData get darkTheme => getDarkTheme();

  // --- Init: call once before runApp ---
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_keyMode);
    final colorInt = prefs.getInt(_keySeedColor);
    final useDynamicBool = prefs.getBool(_keyUseDynamic);

    _instance._themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system, // default
    };

    if (colorInt != null) {
      _instance._seedColor = Color(colorInt);
    } else {
      _instance._seedColor = _defaultSeedColor;
    }

    // Default to dynamic (system wallpaper color) unless explicitly overridden
    if (useDynamicBool != null) {
      _instance._useDynamic = useDynamicBool;
    } else {
      _instance._useDynamic = (colorInt == null);
    }
  }

  // --- Dynamic Color Updates ---
  void updateDynamicColors(ColorScheme? light, ColorScheme? dark) {
    if (_dynamicLight != light || _dynamicDark != dark) {
      _dynamicLight = light;
      _dynamicDark = dark;
      if (_useDynamic && light != null) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('app_theme_widget_accent', light.primary.toARGB32());
        });
      }
    }
  }

  // --- Setters ---
  Future<void> setThemeMode(ThemeMode mode, [Brightness? systemBrightness]) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_keyMode, modeStr);
  }

  Future<void> setUseDynamic(bool useDynamic) async {
    _useDynamic = useDynamic;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseDynamic, useDynamic);
    if (useDynamic && _dynamicLight != null) {
      await prefs.setInt('app_theme_widget_accent', _dynamicLight!.primary.toARGB32());
    } else if (!useDynamic) {
      await prefs.setInt('app_theme_widget_accent', _seedColor.toARGB32());
    }
  }

  Future<void> setSeedColor(Color color, [Brightness? systemBrightness]) async {
    _useDynamic = false;
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseDynamic, false);
    await prefs.setInt(_keySeedColor, color.toARGB32());
    // Propagate to the Android home screen widget immediately
    await prefs.setInt('app_theme_widget_accent', color.toARGB32());
  }
}
