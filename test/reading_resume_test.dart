import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/surah/mushaf_reader.dart';
import 'package:tahfidz_quran/features/surah/surah_detail_page.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('Continue reading restores the exact verse within Juz 1',
      (tester) async {
    await boot(tester);
    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    expect(session.quran.juzForVerse(2, 141), 1);
    expect(session.quran.juzForVerse(2, 142), 2);
    expect(session.quran.juzForVerse(2, 252), 2);
    expect(session.quran.juzForVerse(2, 253), 3);
    expect(session.quran.juzForVerse(114, 6), 30);
    expect(session.quran.juzForVerse(115, 1), isNull);
    await tester.runAsync(() => session.quran.juzVerses(1));

    await session.store.rememberReadingPosition(
      surah: 2,
      verse: 10,
      juz: 1,
    );
    await tester.pumpAndSettle();

    final resume = find.byKey(const Key('home-continue-reading'));
    await tester.scrollUntilVisible(
      resume,
      240,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('home-dashboard-phase-two'),
        ),
        matching: find.byType(Scrollable),
      ).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: resume,
        matching: find.textContaining('Juz 1'),
      ),
      findsOneWidget,
    );
    await tester.tap(resume);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verse-2:10')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(session.store.map('last'), {'surah': 2, 'verse': 10});
    expect(session.store.map('lastReader')['mode'], 'juz');
    expect(session.store.map('lastReader')['juz'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Legacy reading position opens Al-Quran when mode is absent',
      (tester) async {
    await boot(tester);
    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    await session.store.set('last', {'surah': 1, 'verse': 2});
    await tester.pumpAndSettle();

    final resume = find.byKey(const Key('home-continue-reading'));
    await tester.scrollUntilVisible(
      resume,
      240,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('home-dashboard-phase-two'),
        ),
        matching: find.byType(Scrollable),
      ).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: resume,
        matching: find.textContaining('Al-Qur'),
      ),
      findsOneWidget,
    );
    await tester.tap(resume);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(MushafReader), findsOneWidget);
    expect(find.text('Al-Fatihah • 2'), findsOneWidget);
    expect(session.store.map('lastReader')['mode'], 'quran');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reading mode and last ayah persist together across updates',
      (tester) async {
    await boot(tester);
    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    await session.store.rememberReadingPosition(
      surah: 2,
      verse: 142,
      juz: 2,
    );
    final prefs = await SharedPreferences.getInstance();
    final persisted = jsonDecode(prefs.getString('user.v2')!)
        as Map<String, dynamic>;
    expect(persisted['last'], {'surah': 2, 'verse': 142});
    expect((persisted['lastReader'] as Map)['juz'], 2);
    expect((persisted['lastReader'] as Map)['mode'], 'juz');

    // Opening a surah normally switches Resume back to the mushaf reader.
    Navigator.of(root).push(
      MaterialPageRoute<void>(
        builder: (_) => const SurahDetailPage(
          number: 1,
          initialVerse: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(session.store.map('last'), {'surah': 1, 'verse': 3});
    expect(session.store.map('lastReader')['mode'], 'quran');
    expect(session.store.map('lastReader').containsKey('juz'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Stale Juz metadata cannot redirect a legacy reading marker',
      (tester) async {
    await boot(tester);
    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    await session.store.rememberReadingPosition(
      surah: 2,
      verse: 142,
      juz: 2,
    );
    await session.store.set('last', {'surah': 1, 'verse': 2});
    await tester.pumpAndSettle();
    final resume = find.byKey(const Key('home-continue-reading'));
    await tester.scrollUntilVisible(
      resume,
      240,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('home-dashboard-phase-two'),
        ),
        matching: find.byType(Scrollable),
      ).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: resume,
        matching: find.textContaining('Al-Qur'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
