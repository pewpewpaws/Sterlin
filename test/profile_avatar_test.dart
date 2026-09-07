import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sterlin/services/etlab/etlab_data_store.dart';
import 'package:sterlin/widgets/profile_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileAvatar widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders initial letter when no image is available',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              size: 42,
              name: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('renders fallback letter S when name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              size: 42,
              name: '',
            ),
          ),
        ),
      );

      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('renders ProfileAvatarAction with tooltip and avatar',
        (tester) async {
      final store = EtlabDataStore();
      await store.saveProfile({'name': 'Jane Doe'});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: Row(
                children: [
                  ProfileAvatarAction(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfileAvatarAction), findsOneWidget);
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
    });

    test('EtlabDataStore profile image notifier resets on clearAllData',
        () async {
      final store = EtlabDataStore();
      await store.saveProfile({'name': 'Test User'});

      expect(store.profileImageNotifier.value, isNull);

      await store.clearAllData();
      expect(store.profileImagePath, isNull);
      expect(store.profileImageNotifier.value, isNull);
    });
  });
}
