import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';

import 'widget_test.dart' show boot;

void main() {
  for (final dark in [false, true]) {
    testWidgets('Premium home hero and shortcut grid fit small Android dark=$dark',
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

      final hero = find.byKey(const Key('home-premium-hero'));
      expect(hero, findsOneWidget);
      final decoration = tester.widget<Container>(hero).decoration;
      expect(decoration, isA<BoxDecoration>());
      expect((decoration! as BoxDecoration).gradient, isNotNull);
      expect(find.byKey(const Key('home-greeting-headline')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-shortcut-0')),
        190,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 18,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-shortcut-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-shortcut-1')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }
}
