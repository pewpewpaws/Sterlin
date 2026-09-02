import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sterlin/screens/login_screen.dart';
import 'package:sterlin/services/theme_service.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.init();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeService().lightTheme,
      home: const LoginScreen(),
    ));
    await tester.pump();
    expect(find.text('Sterlin'), findsOneWidget);
  });
}
