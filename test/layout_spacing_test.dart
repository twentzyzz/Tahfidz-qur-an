import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/progress/practice_calendar.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('Compact memorization rows and progress are readable with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await boot(tester);
    final session = Session.of(tester.element(find.byType(Scaffold).first));
    final chapter = session.quran.chapters.first;

    await tester.tap(find.byKey(const ValueKey('navigation-3')));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('memorize-surah-1'));
    expect(row, findsOneWidget);
    final latin = find.descendant(of: row, matching: find.text(chapter.name));
    final arabic = find.descendant(of: row, matching: find.text(chapter.arabic));
    expect(latin, findsOneWidget);
    expect(arabic, findsOneWidget);
    expect(tester.getTopLeft(arabic).dy, greaterThan(tester.getTopLeft(latin).dy));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('navigation-4')));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kalender & hasil latihan'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalender & hasil latihan'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeCalendar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
