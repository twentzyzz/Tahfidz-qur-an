import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/settings/backup_page.dart';
import 'package:tahfidz_quran/features/settings/settings_page.dart';

import 'widget_test.dart' show boot;

void main() {
  for (final dark in [false, true]) {
    testWidgets('Premium settings keeps all controls usable at 320 px, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 820);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(tester);
      final session = Session.of(
        tester.element(find.byType(Scaffold).first),
      );
      await session.store.set('dark', dark);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Ibadah yang terasa lebih dekat'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Qari & audio'),
        180,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 10,
      );
      await tester.pumpAndSettle();
      expect(find.text('Qari & audio'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-backup-link')),
        280,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 20,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('settings-backup-link')));
      await tester.pumpAndSettle();
      expect(find.byType(BackupPage), findsOneWidget);
      expect(find.text('Hafalanmu berharga'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
