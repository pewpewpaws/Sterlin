import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sterlin/screens/main_navigation_shell.dart';
import 'package:sterlin/screens/results_screen.dart';
import 'package:sterlin/screens/syllabus_screen.dart';
import 'package:sterlin/services/theme_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_nav_tutorial_seen': true,
    });
    await ThemeService.init();
  });

  testWidgets('MainNavigationShell defines results and syllabus in nav items', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeService().lightTheme,
        home: const MainNavigationShell(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify nav items labels
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Syllabus'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Faculty is gone
    expect(find.text('Faculty'), findsNothing);
  });

  testWidgets('ResultsScreen renders with header and placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeService().lightTheme,
        home: const ResultsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsNWidgets(2)); // header + placeholder
    expect(find.text('Results will appear here'), findsOneWidget);
  });

  testWidgets('SyllabusScreen renders with header and placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeService().lightTheme,
        home: const SyllabusScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Syllabus'), findsNWidgets(2)); // header + placeholder
    expect(find.text('Syllabus details will appear here'), findsOneWidget);
  });
}
