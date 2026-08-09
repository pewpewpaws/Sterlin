import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/etlab_api_service.dart';
import 'services/background_service.dart';
import 'widgets/skeleton_loader.dart';

import 'services/app_logger_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppLoggerService().init();
    AppLoggerService().log('Background task started: $task', category: 'BG_TASK');
    
    try {
      if (task == BackgroundService.dailyFetchTask) {
        final api = EtlabApiService();
        final success = await api.initSession();
        if (success) {
          AppLoggerService().log('Session initialized in background', category: 'BG_TASK');
          await api.fetchAllData();
          AppLoggerService().log('Data fetched successfully in background', category: 'BG_TASK');
        } else {
          AppLoggerService().log('Failed to initialize session in background', category: 'BG_TASK');
        }
      }
    } catch (e) {
      AppLoggerService().log('Background task error: $e', category: 'ERROR');
    }
    
    AppLoggerService().log('Background task finished: $task', category: 'BG_TASK');
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      Workmanager().initialize(
        callbackDispatcher,
      );
    } catch (_) {}
  }
  runApp(const AIPApp());
}

class AIPApp extends StatelessWidget {
  const AIPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sterlin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            maximumSize: const Size(420, 52),
            minimumSize: const Size(64, 44),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: EtlabApiService().initSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: EtlabApiService().isLoggedIn
                  ? const DashboardSkeletonLoader()
                  : const LoginSkeletonLoader(),
            );
          }
          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}

