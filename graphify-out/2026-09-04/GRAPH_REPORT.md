# Graph Report - StudentPlanner  (2026-09-04)

## Corpus Check
- 126 files · ~118,886 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1005 nodes · 1320 edges · 49 communities (38 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Navigation Tutorial & Spotlight
- Windows Plugin Registration
- Background & Storage Services
- Flutter iOS Platform Plugins
- Login & Authentication UI
- Month Calendar View
- Local Notifications Service
- Theme & Styling Service
- Attendance Models & Calculation
- Application Logging Service
- Floating Pill Navigation Bar
- Timetable & Next Class Card
- Attendance Summary Component
- Navigation Shell & Routing
- Linux Desktop Runner
- App Settings Screen
- Android Native Bridge
- Dashboard Screen UI
- Etlab Profile & Models
- Desktop Tray Management
- Animated Navigation Icons
- Android Timetable AppWidget
- Main Navigation Transitions
- Application Entry & Dispatcher
- Common Page Header UI
- Attendance Overview Screen
- Profile Screen UI
- Calendar Bottom Sheets
- Absence Detail Tracking
- Flutter Unit & Widget Tests
- Background Fetch & Periodic Sync
- Windows Native Application Runner
- Teachers Directory Screen
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

## Communities (49 total, 7 thin omitted)

### Community 0 - "Navigation Tutorial & Spotlight"
Cohesion: 0.02
Nodes (82): double?, Duration, action, _advancing, art, attendanceKey, _attendanceRect, _back (+74 more)

### Community 1 - "Windows Plugin Registration"
Cohesion: 0.05
Nodes (57): PluginRegistry, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT (+49 more)

### Community 2 - "Background & Storage Services"
Cohesion: 0.03
Nodes (59): background_service.dart, double get, FlutterSecureStorage, Future, home_widget_service.dart, _accessToken, _activeFetchAllData, _attendanceData (+51 more)

### Community 3 - "Flutter iOS Platform Plugins"
Cohesion: 0.05
Nodes (34): Any, Cocoa, dynamic_color, Flutter, flutter_local_notifications, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+26 more)

### Community 4 - "Login & Authentication UI"
Cohesion: 0.05
Nodes (43): Animation, FormState, _a, build, _c, child, createState, dispose (+35 more)

### Community 5 - "Month Calendar View"
Cohesion: 0.05
Nodes (41): boundary, build, _changeMonth, _clearHighlight, color, createState, danger, dangerContainer (+33 more)

### Community 6 - "Local Notifications Service"
Cohesion: 0.05
Nodes (40): AndroidFlutterLocalNotificationsPlugin, FlutterLocalNotificationsPlugin, IOSFlutterLocalNotificationsPlugin, areNotificationsEnabled, areNotificationsEnabledInPrefs, clearNotificationsData, consumePendingOpen, _flutterLocalNotificationsPlugin (+32 more)

### Community 7 - "Theme & Styling Service"
Cohesion: 0.06
Nodes (35): Color get, ColorScheme?, ColorScheme? get, buildTextTheme, _buttonStyle, darkTheme, _defaultMode, _defaultSeedColor (+27 more)

### Community 8 - "Attendance Models & Calculation"
Cohesion: 0.06
Nodes (35): etlab_models.dart, int get, AttendanceStatus, calculatePercentage, calculateSafeSkips, classesAbsent, classesAttended, classesOnDutyLeave (+27 more)

### Community 9 - "Application Logging Service"
Cohesion: 0.06
Nodes (32): bool get, _addEntry, AppLoggerService, category, clearLogs, formatTimestamp, fromJson, _hookDebugPrint (+24 more)

### Community 10 - "Floating Pill Navigation Bar"
Cohesion: 0.06
Nodes (31): animated_nav_icons.dart, _animateTo, _animController, build, _circleDiameter, _columnWidth, createState, _currentPosition (+23 more)

### Community 11 - "Timetable & Next Class Card"
Cohesion: 0.06
Nodes (30): ClassSession, build, holidayReason, isHoliday, NextClassCardWidget, sessions, build, _buildStatusBadge (+22 more)

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

### Community 19 - "Desktop Tray Management"
Cohesion: 0.09
Nodes (21): dart:async, dispose, init, _initialized, _instance, _keyQuit, _keyToggleWindow, onTrayIconMouseDown (+13 more)

### Community 20 - "Animated Navigation Icons"
Cohesion: 0.10
Nodes (19): AnimationController, Color, dart:math, build, _buildAnimatedBars, _buildAnimatedFaculty, _buildAnimatedHome, _buildBar (+11 more)

### Community 21 - "Android Timetable AppWidget"
Cohesion: 0.16
Nodes (6): Intent, RemoteViews, TimetableViewsFactory, TimetableWidgetService, RemoteViewsFactory, RemoteViewsService

### Community 22 - "Main Navigation Transitions"
Cohesion: 0.18
Nodes (19): _Entrance, _EntranceState, MainNavigationShell, MainNavigationShellState, AnimatedNavIcon, _AnimatedNavIconState, FloatingPillNavBar, _FloatingPillNavBarState (+11 more)

### Community 23 - "Application Entry & Dispatcher"
Cohesion: 0.12
Nodes (16): @pragma, dart:io, build, callbackDispatcher, init, load, main, _sessionFuture (+8 more)

### Community 24 - "Common Page Header UI"
Cohesion: 0.12
Nodes (16): EdgeInsetsGeometry, IconData, Key?, actionKey, actions, eyebrow, icon, implyBackButton (+8 more)

### Community 25 - "Attendance Overview Screen"
Cohesion: 0.14
Nodes (14): DateTime?, int?, AttendanceScreen, _AttendanceScreenState, build, _buildSubjectwiseTab, createState, _currentSemesterLabel (+6 more)

### Community 26 - "Profile Screen UI"
Cohesion: 0.14
Nodes (13): _detailLabels, _DetailRow, _formatValue, _initial, _initialAvatar, label, ProfileAvatarAction, ProfileScreen (+5 more)

### Community 27 - "Calendar Bottom Sheets"
Cohesion: 0.15
Nodes (13): AIPApp, _AttendanceCard, _DaySheet, _HolidayCard, _MonthStat, _PeriodRow, _BellWobble, _DoneCheck (+5 more)

### Community 28 - "Absence Detail Tracking"
Cohesion: 0.15
Nodes (12): AbsenceDetail, date, dayName, formattedDate, hour, key, rawSubject, resolve (+4 more)

### Community 29 - "Flutter Unit & Widget Tests"
Cohesion: 0.19
Nodes (11): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart, package:sterlin/screens/login_screen.dart, package:sterlin/services/theme_service.dart, build, main, _Probe (+3 more)

### Community 30 - "Background Fetch & Periodic Sync"
Cohesion: 0.17
Nodes (11): etlab_api_service.dart, BackgroundService, cancelAll, _ensurePeriodicRegistered, _fastRefresh, _normalRefresh, _periodicUniqueName, scheduleNextRefresh (+3 more)

### Community 31 - "Windows Native Application Runner"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 32 - "Teachers Directory Screen"
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
Cohesion: 0.40
Nodes (5): build, checkAndOpenPendingNotification, openNotificationsPanel, build, MaterialPageRoute

### Community 37 - "Tray & Window Event Listeners"
Cohesion: 0.67
Nodes (3): DesktopTrayService, TrayListener, WindowListener

## Knowledge Gaps
- **595 isolated node(s):** `build_and_install.sh script`, `_sessionFuture`, `main`, `init`, `load` (+590 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 725 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Plugin Registration` to `Flutter iOS Platform Plugins`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `build_and_install.sh script`, `_sessionFuture`, `main` to the rest of the system?**
  _595 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Navigation Tutorial & Spotlight` be split into smaller, more focused modules?**
  _Cohesion score 0.024096385542168676 - nodes in this community are weakly interconnected._
- **Should `Windows Plugin Registration` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `Background & Storage Services` be split into smaller, more focused modules?**
  _Cohesion score 0.03333333333333333 - nodes in this community are weakly interconnected._
- **Should `Flutter iOS Platform Plugins` be split into smaller, more focused modules?**
  _Cohesion score 0.04964539007092199 - nodes in this community are weakly interconnected._
- **Should `Login & Authentication UI` be split into smaller, more focused modules?**
  _Cohesion score 0.048484848484848485 - nodes in this community are weakly interconnected._