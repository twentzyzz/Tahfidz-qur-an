import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/surah/mushaf_reader.dart';
import 'package:tahfidz_quran/features/surah/surah_detail_page.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

import 'widget_test.dart' show boot;

void main() {
  test('Mushaf reading leaves preserve Quran source ayat and their order', () {
    final verses = [
      Verse(1, 1, 'بِسْمِ اللّٰهِ', 'With the name', {}),
      Verse(1, 2, 'الْحَمْدُ لِلّٰهِ', 'Praise', {}),
      Verse(1, 3, 'الرَّحْمَٰنِ', 'Merciful', {}),
    ];
    final leaves = mushafReadingLeaves(verses, maxCharacters: 22);
    expect(leaves.length, greaterThan(1));
    expect(leaves.expand((leaf) => leaf).toList(), orderedEquals(verses));
    expect(mushafReadingLeaves(verses, maxCharacters: 600).length, 1);
    expect(mushafReadingLeaves([]), isEmpty);
  });

  testWidgets('Al-Quran shows multi-ayah mushaf leaves and verse detail actions',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await boot(tester);

    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    Navigator.of(root).push(
      MaterialPageRoute<void>(
        builder: (_) => const SurahDetailPage(number: 1, initialVerse: 2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(MushafReader), findsOneWidget);
    expect(find.byKey(const Key('mushaf-page-view')), findsOneWidget);
    expect(find.byKey(const Key('mushaf-leaf-0')), findsOneWidget);
    expect(find.text('Al-Fatihah • 2'), findsOneWidget);
    final arabic = find.byWidgetPredicate(
      (widget) => widget is SelectableText &&
          (widget.textSpan?.toPlainText() ?? '').contains('بِسْمِ'),
    );
    expect(arabic, findsOneWidget);

    await tester.tap(find.byTooltip('Detail ayat'));
    await tester.pumpAndSettle();
    expect(find.text('Makna ayat'), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Sudah hafal')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sudah hafal'));
    await tester.pumpAndSettle();
    expect(session.store.map('progress')['1:2'], 'done');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Juz remains an entirely vertical ayah list', (tester) async {
    await boot(tester);
    final root = tester.element(find.byType(Scaffold).first);
    final session = Session.of(root);
    await tester.runAsync(() => session.quran.juzVerses(1));
    Navigator.of(root).push(
      MaterialPageRoute<void>(
        builder: (_) => const SurahDetailPage(juz: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MushafReader), findsNothing);
    expect(find.byKey(const Key('mushaf-page-view')), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-1:1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
