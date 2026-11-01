import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/l10n/app_strings.dart';
import 'package:tahfidz_quran/features/prayer/prayer_page.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/prayer_service.dart';
import 'package:tahfidz_quran/services/player_controller.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

void main() {
  testWidgets(
    'Changing city never shows the previous city prayer times while loading',
    (t) async {
      tz.initializeTimeZones();
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance());
      await store.set('city', '1301');
      final gate = Completer<void>();
      final prayer = PrayerService(
        store,
        client: MockClient((r) async {
          final parts = r.url.pathSegments, city = parts[3];
          if (city == '1701') await gate.future;
          final date = DateTime(
            int.parse(parts[4]),
            int.parse(parts[5]),
            int.parse(parts[6]),
          );
          return http.Response(
            jsonEncode({
              'status': true,
              'data': {
                'id': int.parse(city),
                'jadwal': {
                  'date': dateKey(date),
                  for (final k in prayerKeys)
                    k: city == '1301' ? '12:00' : '13:00',
                },
              },
            }),
            200,
          );
        }),
      );
      prayer.cities = [
        {'id': '1301', 'lokasi': 'Jakarta'},
        {'id': '1701', 'lokasi': 'Badung'},
      ];
      final player = PlayerController();
      await t.pumpWidget(
        ListenableBuilder(
          listenable: store,
          builder: (c, _) => Session(
            store: store,
            quran: QuranRepository(),
            player: player,
            prayer: prayer,
            child: const MaterialApp(
              localizationsDelegates: [AppStrings.delegate],
              home: Scaffold(body: PrayerSummary(full: true)),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('12:00'), findsNWidgets(5));
      await store.set('city', '1701');
      await t.pump();
      expect(find.text('12:00'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('13:00'), findsNWidgets(5));
      await t.pumpWidget(const SizedBox());
      player.dispose();
      store.dispose();
      prayer.client.close();
    },
  );
}
