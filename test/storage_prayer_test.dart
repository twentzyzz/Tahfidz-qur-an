import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    data.initializeTimeZones();
  });
  test(
    'Progress bookmarks settings and daily checklist survive store reload',
    () async {
      final prefs = await SharedPreferences.getInstance(),
          s = AppStore(await SharedPreferences.getInstance());
      await s.mark('1:1', 'done');
      await s.bookmark('2:255');
      await s.set('language', 'en');
      await s.set('qari', '03');
      await s.set('last', {'surah': 2, 'verse': 255});
      await s.checkPrayer('2026-11-01', 'subuh', true);
      final restored = AppStore(prefs);
      expect(restored.map('progress')['1:1'], 'done');
      expect(restored.map('bookmarks')['2:255'], true);
      expect(restored.get('language', 'id'), 'en');
      expect(restored.map('last')['verse'], 255);
      expect(restored.map('prayers')['2026-11-02'], isNull);
      expect(restored.map('prayers')['2026-11-01']['subuh'], true);
      await restored.mark('1:1', 'learning');
      expect(restored.map('progress')['1:1'], 'learning');
      expect((restored.data['history'] as List).length, 2);
    },
  );
  test('WIB WITA WIT and local date cross midnight correctly', () {
    final instant = DateTime.utc(2026, 11, 1, 16);
    expect(cityZone('1301'), 'Asia/Jakarta');
    expect(cityZone('1701'), 'Asia/Makassar');
    expect(cityZone('3301'), 'Asia/Jayapura');
    expect(cityZone('2001'), 'Asia/Jakarta');
    expect(cityZone('2201'), 'Asia/Jakarta');
    expect(
      dateKey(tz.TZDateTime.from(instant, tz.getLocation(cityZone('1301')))),
      '2026-11-01',
    );
    expect(
      dateKey(tz.TZDateTime.from(instant, tz.getLocation(cityZone('1701')))),
      '2026-11-02',
    );
    final d = PrayerDay('2026-11-01', '3301', {'subuh': '04:30'}, false);
    expect(d.time('subuh').timeZoneOffset, const Duration(hours: 9));
  });
  test(
    'Validated prayer API caches only same city and date, rejects wrong dates',
    () async {
      final s = AppStore(await SharedPreferences.getInstance());
      final service = PrayerService(
        s,
        client: MockClient(
          (r) async => http.Response(
            jsonEncode({
              'status': true,
              'data': {
                'id': 1301,
                'jadwal': {
                  'date': '2026-11-01',
                  for (final k in prayerKeys) k: '12:00',
                },
              },
            }),
            200,
          ),
        ),
      );
      final d = await service.day('1301', DateTime(2026, 11, 1));
      expect(d.cached, false);
      final offline = PrayerService(
        s,
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect((await offline.day('1301', DateTime(2026, 11, 1))).cached, true);
      await expectLater(
        offline.day('1301', DateTime(2026, 11, 2)),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        service.day('1701', DateTime(2026, 11, 1)),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
