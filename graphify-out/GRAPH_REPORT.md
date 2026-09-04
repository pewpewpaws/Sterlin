# Graph Report - StudentPlanner  (2026-09-04)

## Corpus Check
- 71 files · ~120,009 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1074 nodes · 1406 edges · 55 communities (42 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bacbcbdd`
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
- Application Logging Service
- Floating Pill Navigation Bar
- todays_timetable.dart
- Attendance Summary Component
- Navigation Shell & Routing
- Linux Desktop Runner
- App Settings Screen
- Android Native Bridge
- Dashboard Screen UI
- Etlab Profile & Models
- desktop_tray_service.dart
- Animated Navigation Icons
- Android Timetable AppWidget
- State
- main.dart
- page_header.dart
- Attendance Overview Screen
- Profile Screen UI
- Calendar Bottom Sheets
- Absence Detail Tracking
- package:flutter/material.dart
- Background Fetch & Periodic Sync
- Windows Native Application Runner
- teachers_screen.dart
- Web App Manifest
- Home Screen Widget Integration
- Safeword Protection Service
- Pending Notification Router
- Tray & Window Event Listeners
- Shell Installation Script
- Theme State Management
- Spotlight Painting Canvas
- Month Calendar Component
- Dart Nullable Primitives
- Canvas Geometry Types
- Core String Types
- notifications_screen.dart
- profile_screen.dart
- StatelessWidget
- package:shared_preferences/shared_preferences.dart
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

## Communities (55 total, 9 thin omitted)

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
Cohesion: 0.07
Nodes (28): Animation, FormState, _a, build, _c, child, createState, dispose (+20 more)

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

### Community 9 - "Application Logging Service"
Cohesion: 0.06
Nodes (31): _addEntry, AppLoggerService, category, clearLogs, formatTimestamp, fromJson, _hookDebugPrint, init (+23 more)

### Community 10 - "Floating Pill Navigation Bar"
Cohesion: 0.06
Nodes (31): animated_nav_icons.dart, _animateTo, _animController, build, _circleDiameter, _columnWidth, createState, _currentPosition (+23 more)

### Community 11 - "todays_timetable.dart"
Cohesion: 0.06
Nodes (32): ClassSession, build, holidayReason, isHoliday, NextClassCardWidget, sessions, build, _buildStatusBadge (+24 more)

### Community 12 - "Attendance Summary Component"
Cohesion: 0.07
Nodes (27): GlobalKey, CourseAttendance, _activeHighlight, attendance, attendanceList, AttendanceSummaryWidget, _AttendanceSummaryWidgetState, build (+19 more)

### Community 13 - "Navigation Shell & Routing"
Cohesion: 0.07
Nodes (26): attendance_screen.dart, CurvedAnimation, dashboard_screen.dart, _allNavItems, _attendanceKeyCounter, build, _cachedScreens, createState (+18 more)

### Community 14 - "Linux Desktop Runner"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 15 - "App Settings Screen"
Cohesion: 0.08
Nodes (26): _applyThemeMode, _backgroundStatus, build, _buildBackgroundStatusBadge, _confirmSafeWord, _copyAllLogs, createState, didChangeAppLifecycleState (+18 more)

### Community 16 - "Android Native Bridge"
Cohesion: 0.19
Nodes (11): android, MainActivity, Intent, RemoteViews, TimetableWidgetProvider, AppWidgetManager, AppWidgetProvider, Context (+3 more)

### Community 17 - "Dashboard Screen UI"
Cohesion: 0.09
Nodes (23): _activeWidgets, _attendance, build, _buildDashboardWidget, _checkAndPromptNotificationPermission, createState, DashboardScreen, DashboardScreenState (+15 more)

### Community 18 - "Etlab Profile & Models"
Cohesion: 0.09
Nodes (22): attended, code, email, EtlabProfile, EtlabSubjectAttendance, EtlabTeacher, EtlabTeachersData, EtlabTimetableItem (+14 more)

### Community 19 - "desktop_tray_service.dart"
Cohesion: 0.09
Nodes (21): dart:io, dispose, init, _initialized, _instance, _keyQuit, _keyToggleWindow, onTrayIconMouseDown (+13 more)

### Community 20 - "Animated Navigation Icons"
Cohesion: 0.10
Nodes (19): AnimationController, Color, dart:math, build, _buildAnimatedBars, _buildAnimatedFaculty, _buildAnimatedHome, _buildBar (+11 more)

### Community 21 - "Android Timetable AppWidget"
Cohesion: 0.16
Nodes (6): Intent, RemoteViews, TimetableViewsFactory, TimetableWidgetService, RemoteViewsFactory, RemoteViewsService

### Community 22 - "State"
Cohesion: 0.17
Nodes (21): AttendanceScreen, _AttendanceScreenState, _Entrance, _EntranceState, MainNavigationShell, MainNavigationShellState, AnimatedNavIcon, _AnimatedNavIconState (+13 more)

### Community 23 - "main.dart"
Cohesion: 0.11
Nodes (17): @pragma, AIPApp, build, callbackDispatcher, init, load, main, _sessionFuture (+9 more)

### Community 24 - "page_header.dart"
Cohesion: 0.12
Nodes (15): EdgeInsetsGeometry, IconData, Key?, actionKey, actions, eyebrow, icon, implyBackButton (+7 more)

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
Cohesion: 0.20
Nodes (9): package:flutter/material.dart, package:sterlin/screens/login_screen.dart, package:sterlin/services/theme_service.dart, build, main, _Probe, _wrap, main (+1 more)

### Community 30 - "Background Fetch & Periodic Sync"
Cohesion: 0.17
Nodes (11): etlab_api_service.dart, BackgroundService, cancelAll, _ensurePeriodicRegistered, _fastRefresh, _normalRefresh, _periodicUniqueName, scheduleNextRefresh (+3 more)

### Community 31 - "Windows Native Application Runner"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 32 - "teachers_screen.dart"
Cohesion: 0.20
Nodes (10): build, createState, initState, _isLoading, _loadTeachers, TeachersScreen, _TeachersScreenState, ../models/dashboard_data.dart (+2 more)

### Community 33 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 34 - "Home Screen Widget Integration"
Cohesion: 0.22
Nodes (8): dart:convert, clearWidgetData, HomeWidgetService, _providerName, _sessionToMap, updateHomeScreenWidget, package:flutter/foundation.dart, package:home_widget/home_widget.dart

### Community 35 - "Safeword Protection Service"
Cohesion: 0.22
Nodes (8): code, _key, load, matches, SafeWordService, unlocked, static const String, static final ValueNotifier

### Community 36 - "Pending Notification Router"
Cohesion: 0.14
Nodes (13): Client, dart:async, buildAuthHeaders, buildBaseUrl, EtlabApiClient, fetchAttendanceByDayPeriod, fetchAttendanceBySubject, fetchProfile (+5 more)

### Community 37 - "Tray & Window Event Listeners"
Cohesion: 0.67
Nodes (3): DesktopTrayService, TrayListener, WindowListener

### Community 49 - "notifications_screen.dart"
Cohesion: 0.13
Nodes (15): build, createState, initState, _isLoading, _loadNotifications, _markAllDone, _markDone, _newAbsences (+7 more)

### Community 50 - "profile_screen.dart"
Cohesion: 0.15
Nodes (12): _detailLabels, _formatValue, _initial, _initialAvatar, label, ProfileAvatarAction, ProfileScreen, _showLogoutDialog (+4 more)

### Community 51 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _DetailRow, _AttendanceCard, _DaySheet, _HolidayCard, _MonthStat, _PeriodRow, HeaderAction, NotificationBellAction (+3 more)

### Community 52 - "package:shared_preferences/shared_preferences.dart"
Cohesion: 0.29
Nodes (6): package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart, package:sterlin/services/etlab/etlab_data_store.dart, package:sterlin/services/etlab/user_session_store.dart, main, main

## Knowledge Gaps
- **638 isolated node(s):** `build_and_install.sh script`, `_sessionFuture`, `main`, `init`, `load` (+633 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 781 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Plugin Registration` to `Flutter iOS Platform Plugins`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `build_and_install.sh script`, `_sessionFuture`, `main` to the rest of the system?**
  _638 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `navigation_tutorial.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Should `Windows Plugin Registration` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `Background & Storage Services` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `Flutter iOS Platform Plugins` be split into smaller, more focused modules?**
  _Cohesion score 0.04964539007092199 - nodes in this community are weakly interconnected._
- **Should `login_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._