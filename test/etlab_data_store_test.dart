import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sterlin/services/etlab/etlab_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EtlabDataStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getHolidayStatus detects weekend when no calendar data is present', () {
      final store = EtlabDataStore();
      // Saturday
      final sat = DateTime(2026, 9, 5);
      final satStatus = store.getHolidayStatus(date: sat);
      expect(satStatus.isHoliday, true);
      expect(satStatus.reason, 'Weekend');

      // Sunday
      final sun = DateTime(2026, 9, 6);
      final sunStatus = store.getHolidayStatus(date: sun);
      expect(sunStatus.isHoliday, true);
      expect(sunStatus.reason, 'Weekend');

      // Regular weekday (Friday) without data
      final fri = DateTime(2026, 9, 4);
      final friStatus = store.getHolidayStatus(date: fri);
      expect(friStatus.isHoliday, false);
      expect(friStatus.reason, isNull);
    });

    test('cacheMonthAttendance stores day data and enables getCachedDayData', () async {
      final store = EtlabDataStore();
      final sampleMonthData = {
        'attends': [
          {
            'date': '2026-09-01',
            'holiday': true,
            'holiday_reason': 'Onam Festival',
            'periods': <Map<String, dynamic>>[],
          },
          {
            'date': '2026-09-02',
            'holiday': false,
            'holiday_reason': '',
            'periods': [
              {'attendance': 'P', 'subject': 'CS301'}
            ],
          }
        ]
      };

      await store.cacheMonthAttendance(9, 2026, sampleMonthData, semester: 's5');

      final day1 = store.getCachedDayData(DateTime(2026, 9, 1));
      expect(day1, isNotNull);
      expect(day1!['holiday'], true);
      expect(day1['holiday_reason'], 'Onam Festival');

      final holidayStatus = store.getHolidayStatus(date: DateTime(2026, 9, 1));
      expect(holidayStatus.isHoliday, true);
      expect(holidayStatus.reason, 'Onam Festival');

      final day2 = store.getCachedDayData(DateTime(2026, 9, 2));
      expect(day2, isNotNull);
      expect(day2!['holiday'], false);

      final workDayStatus = store.getHolidayStatus(date: DateTime(2026, 9, 2));
      expect(workDayStatus.isHoliday, false);
    });

    test('clearAllData resets in-memory data', () async {
      final store = EtlabDataStore();
      await store.saveProfile({'student': {'name': 'Alice'}});
      expect(store.profileData, isNotNull);

      await store.clearAllData();
      expect(store.profileData, isNull);
      expect(store.attendanceData, isNull);
      expect(store.teachersData, isNull);
    });
  });
}
