import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'etlab_api_service.dart';

class DesktopTrayService with TrayListener, WindowListener {
  static final DesktopTrayService _instance = DesktopTrayService._internal();
  factory DesktopTrayService() => _instance;
  DesktopTrayService._internal();

  bool _initialized = false;
  Timer? _periodicSyncTimer;

  static const String _keyToggleWindow = 'toggle_window';
  static const String _keyQuit = 'quit';

  Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isLinux && !Platform.isWindows) return;
    if (_initialized) return;

    try {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      trayManager.addListener(this);

      // Set tray icon based on platform
      final iconPath = Platform.isWindows
          ? 'windows/runner/resources/app_icon.ico'
          : 'assets/app_icon_monotone.png';

      await trayManager.setIcon(iconPath);
      if (Platform.isWindows) {
        try {
          await trayManager.setToolTip('Sterlin');
        } catch (_) {}
      }
      await updateContextMenu();

      _startPeriodicSync();
      _initialized = true;
    } catch (e) {
      debugPrint('[ERROR] DesktopTrayService init failed: $e');
    }
  }

  Future<void> updateContextMenu() async {
    try {
      final isVisible = await windowManager.isVisible();
      final menu = Menu(
        items: [
          MenuItem(
            key: _keyToggleWindow,
            label: isVisible ? 'Minimize to Tray' : 'Open Sterlin',
          ),
          MenuItem(
            key: _keyQuit,
            label: 'Quit',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('[ERROR] DesktopTrayService updateContextMenu failed: $e');
    }
  }

  Future<void> toggleWindow() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
      await updateContextMenu();
    } catch (e) {
      debugPrint('[ERROR] DesktopTrayService toggleWindow failed: $e');
    }
  }

  Future<void> quitApp() async {
    try {
      _periodicSyncTimer?.cancel();
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
      await windowManager.destroy();
    } catch (e) {
      debugPrint('[ERROR] DesktopTrayService quit error: $e');
    } finally {
      exit(0);
    }
  }

  // --- WindowListener Callbacks ---

  @override
  void onWindowClose() async {
    // Intercept close: do not quit, hide to system tray
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      await updateContextMenu();
    }
  }

  @override
  void onWindowFocus() {
    updateContextMenu();
  }

  @override
  void onWindowBlur() {
    updateContextMenu();
  }

  // --- TrayListener Callbacks ---

  @override
  void onTrayIconMouseDown() {
    // Left-click on tray icon toggles the app window
    toggleWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == _keyToggleWindow) {
      toggleWindow();
    } else if (menuItem.key == _keyQuit) {
      quitApp();
    }
  }

  // --- Desktop Background Sync ---

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    // Run sync check every 30 minutes in background on desktop
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      try {
        final api = EtlabApiService();
        if (api.isLoggedIn) {
          debugPrint('[DESKTOP_TRAY] Running background attendance sync...');
          await api.fetchAllData();
        }
      } catch (e) {
        debugPrint('[ERROR] Background desktop sync failed: $e');
      }
    });
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }
}
