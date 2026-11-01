import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'app_store.dart';

const prayerKeys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
const prayerId = ['Subuh', 'Zuhur', 'Asar', 'Magrib', 'Isya'];
const prayerEn = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
String cityZone(String id) {
  final p = int.parse(id.substring(0, 2));
  if (p >= 31) return 'Asia/Jayapura';
  if ([17, 18, 19, 21, 23, 24, 25, 26, 27, 28, 29, 30].contains(p)) {
    return 'Asia/Makassar';
  }
  return 'Asia/Jakarta';
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class PrayerDay {
  PrayerDay(this.date, this.city, this.times, this.cached);
  final String date, city;
  final Map<String, String> times;
  final bool cached;
  tz.TZDateTime time(String key) {
    final d = DateTime.parse(date), t = times[key]!.split(':');
    return tz.TZDateTime(
      tz.getLocation(cityZone(city)),
      d.year,
      d.month,
      d.day,
      int.parse(t[0]),
      int.parse(t[1]),
    );
  }
}

class PrayerService {
  PrayerService(this.store, {http.Client? client})
    : client = client ?? http.Client();
  final AppStore store;
  final http.Client client;
  final notifications = FlutterLocalNotificationsPlugin();
  bool notificationReady = false;
  int scheduleGeneration = 0;
  List<Map<String, dynamic>> cities = [];
  Future<void> initialize() async {
    cities = (jsonDecode(
      await rootBundle.loadString('assets/data/cities.json'),
    ) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        notificationReady =
            await notifications.initialize(
              settings: const InitializationSettings(
                android: AndroidInitializationSettings('notification_icon'),
              ),
            ) ??
            false;
      } catch (_) {
        notificationReady = false;
      }
    }
  }

  Future<PrayerDay> day(String city, DateTime date) async {
    final key = dateKey(date), cacheKey = 'schedule.$city.$key';
    try {
      final response = await client
          .get(
            Uri.parse(
              'https://api.myquran.com/v2/sholat/jadwal/$city/${date.year}/${date.month}/${date.day}',
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const FormatException('Schedule unavailable');
      }
      final raw = jsonDecode(response.body) as Map;
      if (raw['status'] != true ||
          '${raw['data']['id']}' != city ||
          raw['data']['jadwal']['date'] != key) {
        throw const FormatException('Schedule mismatch');
      }
      final times = {
        for (final k in prayerKeys) k: raw['data']['jadwal'][k] as String,
      };
      for (final t in times.values) {
        if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(t)) {
          throw const FormatException('Invalid time');
        }
      }
      await store.prefs.setString(cacheKey, jsonEncode(times));
      return PrayerDay(key, city, times, false);
    } catch (_) {
      final cache = store.prefs.getString(cacheKey);
      if (cache == null) rethrow;
      return PrayerDay(
        key,
        city,
        Map<String, String>.from(jsonDecode(cache) as Map),
        true,
      );
    }
  }

  Future<bool> enablePermission() async {
    if (!notificationReady ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return await notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> schedule() async {
    if (!notificationReady ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final generation = ++scheduleGeneration;
    await notifications.cancelAll();
    if (!store.get('notifications', false) || store.get('city', '').isEmpty) {
      return;
    }
    final city = store.get('city', ''), zone = tz.getLocation(cityZone(city));
    final now = tz.TZDateTime.now(zone), lead = store.get('reminder', 10);
    final en = store.get('language', 'id') == 'en';
    var failures = 0;
    for (var d = 0; d < 7; d++) {
      try {
        final date = tz.TZDateTime(zone, now.year, now.month, now.day + d);
        final data = await day(city, date);
        if (generation != scheduleGeneration) return;
        for (var k = 0; k < 5; k++) {
          for (var reminder = 0; reminder < 2; reminder++) {
            final when = data
                .time(prayerKeys[k])
                .subtract(Duration(minutes: reminder == 1 ? lead : 0));
            if (!when.isAfter(now)) continue;
            await notifications.zonedSchedule(
              id: d * 10 + k * 2 + reminder,
              scheduledDate: when,
              title: en ? prayerEn[k] : prayerId[k],
              body: reminder == 1
                  ? (en ? 'Prayer in $lead minutes' : 'Salat $lead menit lagi')
                  : (en ? 'Prayer time' : 'Waktu salat'),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'prayer',
                  'Tahfidz Quran',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      } catch (_) {
        failures++;
      }
    }
    if (failures > 0) throw StateError('Some schedules unavailable');
  }
}
