import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Android scheduling requests permission, schedules local dates and cancels when disabled', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    tz.initializeTimeZones();
    final calls = <MethodCall>[];
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final s = AppStore(await SharedPreferences.getInstance());
    final p = PrayerService(
      s,
      client: MockClient((r) async {
        final parts = r.url.pathSegments;
        final d = DateTime(
          int.parse(parts[parts.length - 3]),
          int.parse(parts[parts.length - 2]),
          int.parse(parts.last),
        );
        return http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'id': 1301,
              'jadwal': {
                'date': dateKey(d),
                for (final k in prayerKeys) k: '12:00',
              },
            },
          }),
          200,
        );
      }),
    );
    await p.initialize();
    expect(await p.enablePermission(), true);
    await s.set('city', '1301');
    await s.set('notifications', true);
    await s.set('reminder', 15);
    await p.schedule();
    expect(
      calls.where((c) => c.method == 'zonedSchedule').length,
      greaterThanOrEqualTo(60),
    );
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      isNotEmpty,
    );
    calls.clear();
    await s.set('notifications', false);
    await p.schedule();
    expect(calls.map((c) => c.method), contains('cancelAll'));
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });
}
