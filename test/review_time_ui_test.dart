import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/settings/settings_page.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('Review reminder time is accessible and updates at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await boot(tester);
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    final tile = find.byKey(const Key('settings-review-time'));
    await tester.scrollUntilVisible(
      tile, 220, scrollable: find.byType(Scrollable).last,
      maxScrolls: 15,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Pukul 08.00'), findsWidgets);

    final session = Session.of(tester.element(tile));
    await session.store.changeReviewReminderTime(20, 30);
    await tester.pumpAndSettle();
    await tester.ensureVisible(tile);
    expect(find.textContaining('Pukul 20.30'), findsWidgets);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    // TimePickerDialog is a modal without an AppBar back button.
    // Dispose the widget tree instead of invoking tester.pageBack().
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
