# Graph Report - Sterlin  (2026-09-07)

## Corpus Check
- 76 files · ~121,681 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1138 nodes · 1501 edges · 57 communities (44 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `515e50e3`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- navigation_tutorial.dart
- Windows Plugin Registration
- etlab_api_service.dart
- Flutter iOS Platform Plugins
- login_screen.dart
- Month Calendar View
- notifications_service.dart
- Theme & Styling Service
- Attendance Models & Calculation
- app_logger_service.dart
- floating_pill_nav_bar.dart
- todays_timetable.dart
- Attendance Summary Component
- main_navigation_shell.dart
- Linux Desktop Runner
- settings_screen.dart
- Android Native Bridge
- dashboard_screen.dart
- Etlab Profile & Models
- desktop_tray_service.dart
- animated_nav_icons.dart
- Android Timetable AppWidget
- etlab_api_client.dart
- _SettingsScreenState
- page_header.dart
- State
- etlab_data_store.dart
- Calendar Bottom Sheets
- Absence Detail Tracking
- package:flutter/material.dart
- Background Fetch & Periodic Sync
- Windows Native Application Runner
- profile_screen.dart
- Web App Manifest
- package:flutter/foundation.dart
- safeword_service.dart
- pulsing_badge.dart
- StatelessWidget
- Shell Installation Script
- Theme State Management
- Spotlight Painting Canvas
- Month Calendar Component
- Dart Nullable Primitives
- Canvas Geometry Types
- Core String Types
- main.dart
- notifications_screen.dart
- profile_avatar.dart
- results_screen.dart
- _HoleHitBlocker
- _RenderHoleHitBlocker
- MaterialPageRoute
- DesktopTrayService

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `TimetableViewsFactory` - 14 edges
3. `MessageHandler` - 12 edges
4. `TimetableWidgetProvider` - 11 edges
5. `FlutterWindow` - 10 edges
6. `Create` - 10 edges
7. `WndProc` - 10 edges
8. `MessageHandler` - 9 edges
9. `_MyApplication` - 7 edges
10. `OnCreate` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (57 total, 9 thin omitted)

### Community 0 - "navigation_tutorial.dart"
Cohesion: 0.03
Nodes (78): action, _advancing, animation, art, attendanceKey, _attendanceRect, _back, bellKey (+70 more)

### Community 1 - "Windows Plugin Registration"
Cohesion: 0.05
Nodes (57): PluginRegistry, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT (+49 more)

### Community 2 - "etlab_api_service.dart"
Cohesion: 0.04
Nodes (49): background_service.dart, etlab/etlab_api_client.dart, etlab/etlab_data_store.dart, etlab/user_session_store.dart, EtlabApiClient get, EtlabDataStore get, home_widget_service.dart, accessToken (+41 more)

### Community 3 - "Flutter iOS Platform Plugins"
Cohesion: 0.05
Nodes (34): Any, Cocoa, dynamic_color, Flutter, flutter_local_notifications, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+26 more)

### Community 4 - "login_screen.dart"
Cohesion: 0.07
Nodes (27): FormState, _a, build, _c, child, createState, dispose, _errorMessage (+19 more)

### Community 5 - "Month Calendar View"
Cohesion: 0.05
Nodes (43): boundary, build, _changeMonth, _clearHighlight, color, createState, danger, dangerContainer (+35 more)

### Community 6 - "notifications_service.dart"
Cohesion: 0.05
Nodes (40): AndroidFlutterLocalNotificationsPlugin, FlutterLocalNotificationsPlugin, IOSFlutterLocalNotificationsPlugin, areNotificationsEnabled, areNotificationsEnabledInPrefs, clearNotificationsData, consumePendingOpen, _flutterLocalNotificationsPlugin (+32 more)

### Community 7 - "Theme & Styling Service"
Cohesion: 0.05
Nodes (37): ChangeNotifier, Color get, ColorScheme?, ColorScheme? get, buildTextTheme, _buttonStyle, darkTheme, _defaultMode (+29 more)

### Community 8 - "Attendance Models & Calculation"
Cohesion: 0.06
Nodes (35): etlab_models.dart, int get, AttendanceStatus, calculatePercentage, calculateSafeSkips, classesAbsent, classesAttended, classesOnDutyLeave (+27 more)

### Community 9 - "app_logger_service.dart"
Cohesion: 0.04
Nodes (45): DateTime?, int?, AttendanceScreen, _AttendanceScreenState, build, _buildSubjectwiseTab, createState, _currentSemesterLabel (+37 more)

### Community 10 - "floating_pill_nav_bar.dart"
Cohesion: 0.06
Nodes (31): animated_nav_icons.dart, _animateTo, _animController, build, _circleDiameter, _columnWidth, createState, _currentPosition (+23 more)

### Community 11 - "todays_timetable.dart"
Cohesion: 0.06
Nodes (37): ClassSession, build, holidayReason, isHoliday, NextClassCardWidget, sessions, build, _buildStatusBadge (+29 more)

### Community 12 - "Attendance Summary Component"
Cohesion: 0.07
Nodes (27): GlobalKey, CourseAttendance, _activeHighlight, attendance, attendanceList, AttendanceSummaryWidget, _AttendanceSummaryWidgetState, build (+19 more)

### Community 13 - "main_navigation_shell.dart"
Cohesion: 0.06
Nodes (33): attendance_screen.dart, CurvedAnimation, dashboard_screen.dart, _allNavItems, _attendanceIndex, _attendanceKeyCounter, build, _cachedScreens (+25 more)

### Community 14 - "Linux Desktop Runner"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 15 - "settings_screen.dart"
Cohesion: 0.08
Nodes (23): _applyThemeMode, _backgroundStatus, build, _buildBackgroundStatusBadge, _confirmSafeWord, _copyAllLogs, createState, didChangeAppLifecycleState (+15 more)

### Community 16 - "Android Native Bridge"
Cohesion: 0.19
Nodes (11): android, MainActivity, Intent, RemoteViews, TimetableWidgetProvider, AppWidgetManager, AppWidgetProvider, Context (+3 more)

### Community 17 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (23): _activeWidgets, _attendance, build, _buildDashboardWidget, _checkAndPromptNotificationPermission, createState, DashboardScreen, DashboardScreenState (+15 more)

### Community 18 - "Etlab Profile & Models"
Cohesion: 0.09
Nodes (22): attended, code, email, EtlabProfile, EtlabSubjectAttendance, EtlabTeacher, EtlabTeachersData, EtlabTimetableItem (+14 more)

### Community 19 - "desktop_tray_service.dart"
Cohesion: 0.10
Nodes (20): dispose, init, _initialized, _instance, _keyQuit, _keyToggleWindow, onTrayIconMouseDown, onTrayIconRightMouseDown (+12 more)

### Community 20 - "animated_nav_icons.dart"
Cohesion: 0.11
Nodes (18): dart:math, build, _buildAnimatedBars, _buildAnimatedHome, _buildAnimatedResults, _buildAnimatedSyllabus, _buildBar, _buildSpinningGear (+10 more)

### Community 21 - "Android Timetable AppWidget"
Cohesion: 0.16
Nodes (6): Intent, RemoteViews, TimetableViewsFactory, TimetableWidgetService, RemoteViewsFactory, RemoteViewsService

### Community 22 - "etlab_api_client.dart"
Cohesion: 0.13
Nodes (14): Client, dart:async, dart:convert, buildAuthHeaders, buildBaseUrl, EtlabApiClient, fetchAttendanceByDayPeriod, fetchAttendanceBySubject (+6 more)

### Community 23 - "_SettingsScreenState"
Cohesion: 0.67
Nodes (3): SettingsScreen, _SettingsScreenState, WidgetsBindingObserver

### Community 24 - "page_header.dart"
Cohesion: 0.12
Nodes (16): EdgeInsetsGeometry, IconData, Key?, actionKey, actions, eyebrow, icon, implyBackButton (+8 more)

### Community 25 - "State"
Cohesion: 0.15
Nodes (23): AIPApp, _AIPAppState, _Entrance, _EntranceState, MainNavigationShell, MainNavigationShellState, AnimatedNavIcon, _AnimatedNavIconState (+15 more)

### Community 26 - "etlab_data_store.dart"
Cohesion: 0.05
Nodes (42): DateTime? get, File, _attendanceData, cacheMonthAttendance, cacheProfileImage, clearAllData, EtlabDataStore, getAllArchivedCalendarData (+34 more)

### Community 27 - "Calendar Bottom Sheets"
Cohesion: 0.08
Nodes (23): bool get, double get, FlutterSecureStorage, _accessToken, clearSession, init, _instance, isLoggedIn (+15 more)

### Community 28 - "Absence Detail Tracking"
Cohesion: 0.15
Nodes (12): AbsenceDetail, date, dayName, formattedDate, hour, key, rawSubject, resolve (+4 more)

### Community 29 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (21): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart, package:sterlin/screens/login_screen.dart, package:sterlin/screens/main_navigation_shell.dart, package:sterlin/screens/results_screen.dart, package:sterlin/screens/syllabus_screen.dart, package:sterlin/services/etlab/etlab_data_store.dart (+13 more)

### Community 30 - "Background Fetch & Periodic Sync"
Cohesion: 0.17
Nodes (11): etlab_api_service.dart, BackgroundService, cancelAll, _ensurePeriodicRegistered, _fastRefresh, _normalRefresh, _periodicUniqueName, scheduleNextRefresh (+3 more)

### Community 31 - "Windows Native Application Runner"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 32 - "profile_screen.dart"
Cohesion: 0.15
Nodes (12): build, _detailLabels, _DetailRow, _formatValue, label, ProfileScreen, _showLogoutDialog, value (+4 more)

### Community 33 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 34 - "package:flutter/foundation.dart"
Cohesion: 0.22
Nodes (8): clearWidgetData, HomeWidgetService, _providerName, _sessionToMap, updateHomeScreenWidget, ../models/dashboard_data.dart, package:flutter/foundation.dart, package:home_widget/home_widget.dart

### Community 35 - "safeword_service.dart"
Cohesion: 0.22
Nodes (8): code, _key, load, matches, SafeWordService, unlocked, static const String, static final ValueNotifier

### Community 36 - "pulsing_badge.dart"
Cohesion: 0.15
Nodes (12): Animation, AnimationController, Color, _animation, backgroundColor, build, _controller, createState (+4 more)

### Community 37 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): _AttendanceCard, _DaySheet, _HolidayCard, _MonthStat, _PeriodRow, HeaderAction, NotificationBellAction, PageHeader (+4 more)

### Community 49 - "main.dart"
Cohesion: 0.11
Nodes (17): @pragma, Future, build, callbackDispatcher, createState, init, initState, load (+9 more)

### Community 50 - "notifications_screen.dart"
Cohesion: 0.13
Nodes (15): build, createState, initState, _isLoading, _loadNotifications, _markAllDone, _markDone, _newAbsences (+7 more)

### Community 51 - "profile_avatar.dart"
Cohesion: 0.13
Nodes (14): dart:io, backgroundColor, borderColor, borderWidth, _buildInitials, imageUrl, localImagePath, name (+6 more)

### Community 52 - "results_screen.dart"
Cohesion: 0.21
Nodes (10): build, createState, ResultsScreen, _ResultsScreenState, build, createState, SyllabusScreen, _SyllabusScreenState (+2 more)

### Community 55 - "MaterialPageRoute"
Cohesion: 0.40
Nodes (5): checkAndOpenPendingNotification, openNotificationsPanel, build, build, MaterialPageRoute

### Community 56 - "DesktopTrayService"
Cohesion: 0.67
Nodes (3): DesktopTrayService, TrayListener, WindowListener

## Knowledge Gaps
- **680 isolated node(s):** `build_and_install.sh script`, `_sessionFuture`, `main`, `init`, `load` (+675 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 828 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Plugin Registration` to `Flutter iOS Platform Plugins`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `build_and_install.sh script`, `_sessionFuture`, `main` to the rest of the system?**
  _680 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `navigation_tutorial.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Should `Windows Plugin Registration` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `etlab_api_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Flutter iOS Platform Plugins` be split into smaller, more focused modules?**
  _Cohesion score 0.04964539007092199 - nodes in this community are weakly interconnected._
- **Should `login_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._