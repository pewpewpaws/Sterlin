import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planner/main.dart';

void main() {
  testWidgets('App renders login screen when no stored session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AIPApp());
    await tester.pumpAndSettle();
    expect(find.text('Sterlin'), findsWidgets);
  });
}
