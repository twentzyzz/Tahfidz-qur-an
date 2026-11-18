import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/surah/surah_detail_page.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('Ayat read continuously with vertical scroll and keep resume verse',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await boot(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final session = Session.of(context);
    await tester.runAsync(() => session.quran.juzVerses(1));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SurahDetailPage(juz: 1, initialVerse: 2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-1:2')), findsOneWidget);
    expect(find.text('Al-Fatihah • 2'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('verse-1:3')),
      350,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ).first,
      maxScrolls: 20,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('verse-1:3')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // After a completed scroll, last-read is updated to a visible ayat.
    final last = session.store.map('last');
    expect(last['surah'], 1);
    expect(last['verse'], greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Verse navigation uses vertical positions, not horizontal pages',
      (tester) async {
    await boot(tester);
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(() => Session.of(context).quran.juzVerses(1));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SurahDetailPage(juz: 1),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('verse-1:1')), findsOneWidget);

    await tester.tap(find.byTooltip('Ayat berikutnya'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('verse-1:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('vertical-reader-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
