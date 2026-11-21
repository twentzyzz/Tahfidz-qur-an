import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/surah/mushaf_reader.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

import 'widget_test.dart' show boot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic harakat and alef variants do not prevent matches', () {
    expect(normalizeVerseSearchText('بِسْمِ اللّٰهِ'), 'بسم الله');
    expect(normalizeVerseSearchText('إِلَىٰ  ٱللَّهِ'), 'الي الله');
    expect(normalizeVerseSearchText('  SeGaLa  PUJI, '), 'segala puji');
  });

  test('Offline search finds exact verse references across Arabic and Indonesian',
      () async {
    final quran = QuranRepository();
    await quran.initialize();

    final indonesian = await quran.searchVerses('  SEGALA  PUJI  ');
    expect(indonesian.total, greaterThan(0));
    expect(indonesian.matches.first.verse.ref, '1:2');
    expect(indonesian.matches.first.inTranslation, isTrue);

    final arabic = await quran.searchVerses('الْحَمْدُ');
    expect(arabic.matches.first.verse.ref, '1:2');
    expect(arabic.matches.first.inArabic, isTrue);

    final noHarakat = await quran.searchVerses('بسم الله');
    expect(noHarakat.matches.first.verse.ref, '1:1');
    expect(noHarakat.matches.first.inArabic, isTrue);

    final limited = await quran.searchVerses('الله', limit: 3);
    expect(limited.matches.length, 3);
    expect(limited.total, greaterThan(3));

    expect((await quran.searchVerses('')).total, 0);
    expect((await quran.searchVerses('kalimayangsangattidakada')).total, 0);
    expect((await quran.searchVerses('الله', limit: 0)).matches, isEmpty);
  });

  testWidgets('Search Indonesian verse and open its exact mushaf position',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Al-Qur’an').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-verse-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('verse-search-input')), findsOneWidget);
    // Prepare the full offline index in the real async zone first. Loading
    // 114 assets from a fake-async debounce callback can otherwise deadlock
    // widget tests while waiting for file bundle continuations.
    final root = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => Session.of(root).quran.searchVerses('segala puji'),
    );
    await tester.enterText(
      find.byKey(const Key('verse-search-input')),
      'segala puji',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('verse-result-1:2'));
    expect(first, findsOneWidget);
    await tester.tap(first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(MushafReader), findsOneWidget);
    expect(find.text('Al-Fatihah • 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Clearing the search cancels obsolete results', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Al-Qur’an').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-verse-search')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('verse-search-input'));
    await tester.enterText(field, 'segala puji');
    await tester.enterText(field, '');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('verse-search-loading')), findsNothing);
    expect(find.byKey(const ValueKey('verse-result-1:2')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
