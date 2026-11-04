import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/widgets/weekly_progress.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/features/surah/surah_list_page.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

import 'widget_test.dart' show boot;

void main() {
  test('Weekly activity deduplicates marks and excludes reset verses', () {
    final counts = weeklyCounts(
      {'1:1': 'done', '1:2': 'none', '1:3': 'done'},
      [
        {'ref': '1:1', 'status': 'done', 'time': '2026-11-04T09:00:00'},
        {'ref': '1:1', 'status': 'done', 'time': '2026-11-04T10:00:00'},
        {'ref': '1:2', 'status': 'done', 'time': '2026-11-04T10:00:00'},
        {'ref': '1:3', 'status': 'done', 'time': '2026-11-03T10:00:00'},
      ],
      DateTime(2026, 11, 4),
    );
    expect(counts, [0, 0, 0, 0, 0, 1, 1]);
  });

  test(
    'Displayed juz endings match the final verse in each bundled juz',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final q = QuranRepository();
      await q.initialize();
      for (var i = 0; i < 30; i++) {
        final end = (await q.juzVerses(i + 1)).last;
        expect(
          juzEnd(q, i),
          '${q.chapters[end.surah - 1].name} : ${end.number}',
        );
      }
    },
  );

  testWidgets(
    'Qari search, favorites and selection persist at narrow large text sizes',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(t);
      await t.tap(find.byTooltip('Pengaturan'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Qari & audio'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await t.tap(find.text('Qari & audio'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Yasser');
      await t.pumpAndSettle();
      await t.ensureVisible(find.byTooltip('Jadikan Qari Favorit'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Jadikan Qari Favorit'));
      await t.pumpAndSettle();
      await t.tap(find.text('Yasser Al-Dosari'));
      await t.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final reloaded = AppStore(prefs);
      expect(reloaded.map('favoriteQaris'), {'06': true});
      expect(reloaded.get('qari', ''), '06');
      await t.ensureVisible(find.byType(TextField));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'zzzz');
      await t.pumpAndSettle();
      expect(find.textContaining('Tidak ada qari yang cocok'), findsOneWidget);
      expect(t.takeException(), isNull);
      reloaded.dispose();
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Home resumes saved memorization rather than the reading bookmark',
    (t) async {
      await boot(t);
      final session = Session.of(t.element(find.byType(Scaffold).first));
      await session.store.set('last', {'surah': 2, 'verse': 4});
      await session.store.set('lastMemorization', {'surah': 1, 'verse': 2});
      await t.pumpAndSettle();
      await t.tap(find.text('Lanjutkan'));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      expect(find.byTooltip('Sembunyikan / tampilkan Arab'), findsOneWidget);
      expect(find.text('Al-Fatihah • 2'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('user.v2')!) as Map;
      expect(saved['last'], {'surah': 2, 'verse': 4});
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
