import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sterlin/services/etlab/user_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserSessionStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default state has sctce subdomain and 0.75 target attendance pct', () {
      final store = UserSessionStore();
      expect(store.subdomain, 'sctce');
      expect(store.targetAttendancePct, 0.75);
      expect(store.isLoggedIn, false);
      expect(store.username, isNull);
      expect(store.accessToken, isNull);
    });

    test('setTargetAttendancePct clamps values below 75%', () async {
      final store = UserSessionStore();
      await store.setTargetAttendancePct(0.60);
      expect(store.targetAttendancePct, 0.75);

      await store.setTargetAttendancePct(0.85);
      expect(store.targetAttendancePct, 0.85);
    });
  });
}
