import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'services/etlab_api_service.dart';
import 'services/app_logger_service.dart';
import 'services/background_service.dart';
import 'services/theme_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppLoggerService().init();
    debugPrint('[BG_TASK] Background task started: $task');
    
    try {
      if (task == BackgroundService.widgetRefreshTask) {
        final api = EtlabApiService();
        final success = await api.initSession();
        if (success) {
          debugPrint('[BG_TASK] Session initialized in background');
          await api.fetchAllData();
          debugPrint('[BG_TASK] Data fetched successfully in background');
        } else {
          debugPrint('[BG_TASK] Failed to initialize session in background');
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Background task error: $e');
    }
    
    debugPrint('[BG_TASK] Background task finished: $task');
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
    ),
  );
  await AppLoggerService().init();
  await ThemeService.init();
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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeService().updateDynamicColors(lightDynamic, darkDynamic);
        return ListenableBuilder(
          listenable: ThemeService(),
          builder: (context, _) {
            final ts = ThemeService();
            return MaterialApp(
              title: 'Sterlin',
              debugShowCheckedModeBanner: false,
              themeMode: ts.themeMode,
              theme: ts.getLightTheme(lightDynamic),
              darkTheme: ts.getDarkTheme(darkDynamic),
              home: FutureBuilder<bool>(
                future: EtlabApiService().initSession(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final isLoggedIn = snapshot.data ?? false;
                  return isLoggedIn ? const MainNavigationShell() : const LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}
