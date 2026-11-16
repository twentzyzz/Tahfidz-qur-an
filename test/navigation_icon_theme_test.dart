import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/core/constants/app_icons.dart';

import 'widget_test.dart' show boot;

void main() {
  for (final dark in [false, true]) {
    testWidgets('Premium navigation icon pairs work at 320 px, dark=$dark',
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
      final navigation = find.byKey(const Key('compact-bottom-navigation'));
      expect(navigation, findsOneWidget);
      expect(AppIcons.navigation.length, 5);
      expect(AppIcons.selectedNavigation.length, 5);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(ValueKey('navigation-$i')));
        await tester.pumpAndSettle();
        final selectedIcon = find.descendant(
          of: find.byKey(ValueKey('navigation-icon-$i')),
          matching: find.byIcon(AppIcons.selectedNavigation[i]),
        );
        expect(selectedIcon, findsOneWidget);
        for (var j = 0; j < 5; j++) {
          final tabIcon = find.descendant(
            of: find.byKey(ValueKey('navigation-icon-$j')),
            matching: find.byIcon(
              j == i ? AppIcons.selectedNavigation[j] : AppIcons.navigation[j],
            ),
          );
          expect(tabIcon, findsOneWidget);
          expect(
            tester.getSize(find.byKey(ValueKey('navigation-$j'))).height,
            greaterThanOrEqualTo(48),
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
