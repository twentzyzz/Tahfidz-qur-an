import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/surah/surah_detail_page.dart';

import 'widget_test.dart' show boot;

void main() {
  for (final width in [320.0, 390.0, 1024.0]) {
    for (final dark in [false, true]) {
      testWidgets('Phase one at width $width, dark=$dark, text scale 2', (t) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await boot(t);
        final session = Session.of(t.element(find.byType(Scaffold).first));
        await session.store.set('dark', dark);
        await session.store.set('language', dark ? 'en' : 'id');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        await t.scrollUntilVisible(
          find.text(dark ? 'Verse bookmarks' : 'Bookmark ayat'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(t.takeException(), isNull);

        for (var i = 0; i < 5; i++) {
          final target = find.byKey(ValueKey('navigation-$i'));
          expect(t.getSize(target).height, greaterThanOrEqualTo(48));
          expect(t.getSize(target).width, greaterThanOrEqualTo(48));
        }
        await t.tap(find.byKey(const ValueKey('navigation-1')));
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('surah-search')), '111');
        await t.pumpAndSettle();
        expect(find.text('Al-Lahab'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.enterText(find.byKey(const Key('surah-search')), 'zzzz');
        await t.pumpAndSettle();
        await t.ensureVisible(find.text(dark ? 'Show all surahs' : 'Tampilkan semua surah'));
        await t.tap(find.text(dark ? 'Show all surahs' : 'Tampilkan semua surah'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const Key('surah-search')));
        expect(find.text('Al-Fatihah'), findsOneWidget);

        await t.tap(find.byKey(const ValueKey('navigation-2')));
        await t.pumpAndSettle();
        expect(find.text('Juz 1'), findsOneWidget);
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('juz-30')),
          400,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 100,
        );
        expect(find.textContaining('An-Nas : 6'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const ValueKey('navigation-1')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('surah-search')), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('Arabic search, clear, and juz selection retain reader routes', (t) async {
    await boot(t);
    final session = Session.of(t.element(find.byType(Scaffold).first));
    await t.tap(find.byKey(const ValueKey('navigation-1')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('surah-search')), session.quran.chapters.first.arabic);
    await t.pumpAndSettle();
    expect(find.text('Al-Fatihah'), findsOneWidget);
    await t.tap(find.byTooltip('Hapus pencarian'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(find.byKey(const Key('surah-search'))).controller!.text, isEmpty);
    await t.tap(find.byKey(const ValueKey('navigation-2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('juz-1')));
    await t.pumpAndSettle();
    expect(t.widget<SurahDetailPage>(find.byType(SurahDetailPage)).juz, 1);
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Bottom navigation exposes selection and supports keyboard', (t) async {
    await boot(t);
    final handle = t.ensureSemantics();
    addTearDown(handle.dispose);
    final target = find.byKey(const ValueKey('navigation-1'));
    final semantics = find.ancestor(of: target, matching: find.byType(Semantics)).first;
    expect(t.getSemantics(semantics).label, 'Al-Qur’an');
    expect(t.widget<Semantics>(semantics).properties.selected, isFalse);
    final icon = find.descendant(of: target, matching: find.byType(Icon));
    Focus.of(t.element(icon)).requestFocus();
    await t.pump();
    expect(Focus.of(t.element(icon)).hasPrimaryFocus, isTrue);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(t.widget<Semantics>(semantics).properties.selected, isTrue);
    expect(find.byKey(const Key('surah-search')), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
