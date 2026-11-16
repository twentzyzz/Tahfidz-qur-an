import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';

import 'widget_test.dart' show boot;

Future<void> openReview(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('navigation-3')));
  await t.pumpAndSettle();
  await t.tap(find.text('Murajaah terjadwal'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Empty murajaah has guidance and a working memorization action',
      (t) async {
    t.view.physicalSize = const Size(360, 780);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await boot(t);
    await openReview(t);
    expect(find.byKey(const Key('murajaah-empty')), findsOneWidget);
    expect(find.text('Belum ada jadwal murajaah'), findsOneWidget);
    expect(find.byKey(const Key('murajaah-upcoming-empty')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('murajaah-start-memorization')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('murajaah-start-memorization')));
    await t.pumpAndSettle();
    expect(find.text('Pilih surah hafalan'), findsOneWidget);
    expect(find.text('Al-Fatihah'), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Due and upcoming memorized verses render as readable cards',
      (t) async {
    await boot(t);
    final session = Session.of(t.element(find.byType(Scaffold).first));
    final today = DateTime.now();
    await session.store.mark('1:1', 'done',
        at: today.subtract(const Duration(days: 2)));
    await session.store.mark('1:2', 'done', at: today);
    await t.pumpAndSettle();
    await openReview(t);
    expect(find.byKey(const ValueKey('murajaah-due-1:1')), findsOneWidget);
    expect(find.byKey(const ValueKey('murajaah-upcoming-1:2')),
        findsOneWidget);
    expect(find.byKey(const Key('murajaah-empty')), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Review page remains scrollable at large text scale in dark mode',
      (t) async {
    t.view.physicalSize = const Size(320, 740);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await boot(t);
    final session = Session.of(t.element(find.byType(Scaffold).first));
    await session.store.set('dark', true);
    await t.pumpAndSettle();
    await openReview(t);
    await t.scrollUntilVisible(
      find.byKey(const Key('murajaah-guide')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('murajaah-guide')), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
