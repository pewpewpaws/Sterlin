import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planner/services/theme_service.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(brightness == Brightness.dark ? 'DARK' : 'LIGHT'),
    );
  }
}

Widget _wrap() {
  return ListenableBuilder(
    listenable: ThemeService(),
    builder: (context, _) {
      final ts = ThemeService();
      return MaterialApp(
        themeMode: ts.themeMode,
        theme: ts.getLightTheme(null),
        darkTheme: ts.getDarkTheme(null),
        home: const _Probe(),
      );
    },
  );
}

void main() {
  testWidgets('theme mode switches apply under dark system', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.init();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    Brightness resolved() => tester
        .widget<Text>(find.byType(Text))
        .data!
        .contains('DARK')
        ? Brightness.dark
        : Brightness.light;

    expect(ThemeService().themeMode, ThemeMode.system);
    expect(find.text('DARK'), findsOneWidget,
        reason: 'system dark should render dark');

    await ThemeService().setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(ThemeService().themeMode, ThemeMode.light);
    expect(resolved(), Brightness.light);

    await ThemeService().setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(ThemeService().themeMode, ThemeMode.dark);
    expect(resolved(), Brightness.dark, reason: 'forced Dark must apply');

    await ThemeService().setThemeMode(ThemeMode.system);
    await tester.pumpAndSettle();
    expect(find.text('DARK'), findsOneWidget);
  });
}
