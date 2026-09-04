# Graph Report - StudentPlanner  (2026-09-04)

## Corpus Check
- 73 files · ~120,241 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1089 nodes · 1428 edges · 49 communities (36 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c1c3ed2e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- navigation_tutorial.dart
- Windows Plugin Registration
- Background & Storage Services
- Flutter iOS Platform Plugins
- login_screen.dart
- Month Calendar View
- Local Notifications Service
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
- SingleTickerProviderStateMixin
- State
- page_header.dart
- Attendance Overview Screen
- Profile Screen UI
- Calendar Bottom Sheets
- Absence Detail Tracking
- package:flutter/material.dart
- Background Fetch & Periodic Sync
- Windows Native Application Runner
- results_screen.dart
- Web App Manifest
- home_widget_service.dart
- package:flutter/foundation.dart
- Shell Installation Script
- Theme State Management
- Spotlight Painting Canvas
- Month Calendar Component
- Dart Nullable Primitives
- Canvas Geometry Types
- Core String Types
- _HoleHitBlocker
- _RenderHoleHitBlocker

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

## Communities (49 total, 9 thin omitted)

### Community 0 - "navigation_tutorial.dart"
Cohesion: 0.03
Nodes (78): action, _advancing, animation, art, attendanceKey, _attendanceRect, _back, bellKey (+70 more)

### Community 1 - "Windows Plugin Registration"
Cohesion: 0.05
Nodes (57): PluginRegistry, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT (+49 more)

### Community 2 - "Background & Storage Services"
Cohesion: 0.04
Nodes (47): background_service.dart, etlab/etlab_api_client.dart, etlab/etlab_data_store.dart, etlab/user_session_store.dart, EtlabApiClient get, EtlabDataStore get, Future, home_widget_service.dart (+39 more)

### Community 3 - "Flutter iOS Platform Plugins"
Cohesion: 0.05
Nodes (34): Any, Cocoa, dynamic_color, Flutter, flutter_local_notifications, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+26 more)

### Community 4 - "login_screen.dart"
Cohesion: 0.05
Nodes (43): Animation, FormState, _a, build, _c, child, createState, dispose (+35 more)

### Community 5 - "Month Calendar View"
Cohesion: 0.05
Nodes (43): boundary, build, _changeMonth, _clearHighlight, color, createState, danger, dangerContainer (+35 more)

### Community 6 - "Local Notifications Service"
Cohesion: 0.04
Nodes (45): AndroidFlutterLocalNotificationsPlugin, FlutterLocalNotificationsPlugin, IOSFlutterLocalNotificationsPlugin, build, areNotificationsEnabled, areNotificationsEnabledInPrefs, checkAndOpenPendingNotification, clearNotificationsData (+37 more)

### Community 7 - "Theme & Styling Service"
Cohesion: 0.05
Nodes (37): ChangeNotifier, Color get, ColorScheme?, ColorScheme? get, buildTextTheme, _buttonStyle, darkTheme, _defaultMode (+29 more)

### Community 8 - "Attendance Models & Calculation"
Cohesion: 0.06
Nodes (35): etlab_models.dart, int get, AttendanceStatus, calculatePercentage, calculateSafeSkips, classesAbsent, classesAttended, classesOnDutyLeave (+27 more)

### Community 9 - "app_logger_service.dart"
Cohesion: 0.04
Nodes (44): Client, dart:async, _addEntry, AppLoggerService, category, clearLogs, formatTimestamp, fromJson (+36 more)

### Community 10 - "floating_pill_nav_bar.dart"
Cohesion: 0.06
Nodes (33): animated_nav_icons.dart, _animateTo, _animController, build, _circleDiameter, _columnWidth, createState, _currentPosition (+25 more)

### Community 11 - "todays_timetable.dart"
Cohesion: 0.06
Nodes (32): ClassSession, build, holidayReason, isHoliday, sessions, build, _buildStatusBadge, createState (+24 more)

### Community 12 - "Attendance Summary Component"
Cohesion: 0.07
Nodes (27): GlobalKey, CourseAttendance, _activeHighlight, attendance, attendanceList, AttendanceSummaryWidget, _AttendanceSummaryWidgetState, build (+19 more)

### Community 13 - "main_navigation_shell.dart"
Cohesion: 0.06
Nodes (35): attendance_screen.dart, CurvedAnimation, dashboard_screen.dart, _allNavItems, _attendanceIndex, _attendanceKeyCounter, build, _cachedScreens (+27 more)

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
Cohesion: 0.10
Nodes (21): _activeWidgets, _attendance, build, _buildDashboardWidget, _checkAndPromptNotificationPermission, createState, DashboardWidgetType, DashboardWidgetTypeExtension (+13 more)

### Community 18 - "Etlab Profile & Models"
Cohesion: 0.09
Nodes (22): attended, code, email, EtlabProfile, EtlabSubjectAttendance, EtlabTeacher, EtlabTeachersData, EtlabTimetableItem (+14 more)

### Community 19 - "desktop_tray_service.dart"
Cohesion: 0.05
Nodes (39): @pragma, dart:io, build, callbackDispatcher, init, load, main, _sessionFuture (+31 more)

### Community 20 - "animated_nav_icons.dart"
Cohesion: 0.09
Nodes (22): AnimationController, Color, dart:math, AnimatedNavIcon, _AnimatedNavIconState, build, _buildAnimatedBars, _buildAnimatedHome (+14 more)

### Community 21 - "Android Timetable AppWidget"
Cohesion: 0.16
Nodes (6): Intent, RemoteViews, TimetableViewsFactory, TimetableWidgetService, RemoteViewsFactory, RemoteViewsService

### Community 22 - "SingleTickerProviderStateMixin"
Cohesion: 0.18
Nodes (11): _Entrance, _EntranceState, _BellWobble, _BellWobbleState, _DoneCheck, _DoneCheckState, _TutorialOverlay, _TutorialOverlayState (+3 more)

### Community 23 - "State"
Cohesion: 0.28
Nodes (9): AttendanceScreen, _AttendanceScreenState, DashboardScreen, DashboardScreenState, SettingsScreen, _SettingsScreenState, State, StatefulWidget (+1 more)

### Community 24 - "page_header.dart"
Cohesion: 0.05
Nodes (41): EdgeInsetsGeometry, IconData, Key?, AIPApp, _detailLabels, _DetailRow, _formatValue, _initial (+33 more)

### Community 25 - "Attendance Overview Screen"
Cohesion: 0.15
Nodes (12): DateTime?, int?, build, _buildSubjectwiseTab, createState, _currentSemesterLabel, highlightSubject, initialTabIndex (+4 more)

### Community 26 - "Profile Screen UI"
Cohesion: 0.06
Nodes (33): DateTime? get, _attendanceData, cacheMonthAttendance, clearAllData, EtlabDataStore, getAllArchivedCalendarData, getCachedDayData, getCachedMonthAttendance (+25 more)

### Community 27 - "Calendar Bottom Sheets"
Cohesion: 0.08
Nodes (23): bool get, double get, FlutterSecureStorage, _accessToken, clearSession, init, _instance, isLoggedIn (+15 more)

### Community 28 - "Absence Detail Tracking"
Cohesion: 0.15
Nodes (12): AbsenceDetail, date, dayName, formattedDate, hour, key, rawSubject, resolve (+4 more)

### Community 29 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (19): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart, package:sterlin/screens/login_screen.dart, package:sterlin/screens/main_navigation_shell.dart, package:sterlin/screens/results_screen.dart, package:sterlin/screens/syllabus_screen.dart, package:sterlin/services/etlab/etlab_data_store.dart (+11 more)

### Community 30 - "Background Fetch & Periodic Sync"
Cohesion: 0.17
Nodes (11): etlab_api_service.dart, BackgroundService, cancelAll, _ensurePeriodicRegistered, _fastRefresh, _normalRefresh, _periodicUniqueName, scheduleNextRefresh (+3 more)

### Community 31 - "Windows Native Application Runner"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 32 - "results_screen.dart"
Cohesion: 0.21
Nodes (10): build, createState, ResultsScreen, _ResultsScreenState, build, createState, SyllabusScreen, _SyllabusScreenState (+2 more)

### Community 33 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 34 - "home_widget_service.dart"
Cohesion: 0.22
Nodes (8): dart:convert, clearWidgetData, HomeWidgetService, _providerName, _sessionToMap, updateHomeScreenWidget, package:home_widget/home_widget.dart, static const String

### Community 35 - "package:flutter/foundation.dart"
Cohesion: 0.22
Nodes (8): code, _key, load, matches, SafeWordService, unlocked, package:flutter/foundation.dart, static final ValueNotifier

## Knowledge Gaps
- **645 isolated node(s):** `build_and_install.sh script`, `_sessionFuture`, `main`, `init`, `load` (+640 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 791 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Plugin Registration` to `Flutter iOS Platform Plugins`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `build_and_install.sh script`, `_sessionFuture`, `main` to the rest of the system?**
  _645 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `navigation_tutorial.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Should `Windows Plugin Registration` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `Background & Storage Services` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `Flutter iOS Platform Plugins` be split into smaller, more focused modules?**
  _Cohesion score 0.04964539007092199 - nodes in this community are weakly interconnected._
- **Should `login_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.048484848484848485 - nodes in this community are weakly interconnected._