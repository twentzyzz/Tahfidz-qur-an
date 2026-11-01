import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/app/app.dart';

Future<void> boot(WidgetTester t) async {
  rootBundle.clear();
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(const TahfidzApp());
  for (
    var i = 0;
    i < 30 && find.byType(NavigationBar).evaluate().isEmpty;
    i++
  ) {
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(NavigationBar), findsOneWidget);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'Bottom navigation, search, real verse reader, bookmark and progress',
    (t) async {
      await boot(t);
      await t.tap(find.text('Daftar Surah'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Al-Fatihah');
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ListTile, 'Al-Fatihah'));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && (w.data ?? '').contains('بِسْمِ'),
        ),
        findsOneWidget,
      );
      await t.scrollUntilVisible(
        find.byTooltip('Bookmark'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await t.tap(find.byTooltip('Bookmark'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Sudah hafal'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await t.tap(find.text('Sudah hafal'));
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Progres').last);
      await t.pumpAndSettle();
      expect(find.text('1 / 6236 ayat sudah hafal'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Language and dark theme controls persist on a narrow screen', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await boot(t);
    await t.tap(find.byTooltip('Pengaturan'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('English').last);
    await t.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    await t.tap(find.byType(SwitchListTile).first);
    await t.pumpAndSettle();
    expect(
      Theme.of(t.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Tahfidz hides Arabic and selecting qari persists', (t) async {
    await boot(t);
    await t.tap(find.text('Mulai Menghafal'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Al-Fatihah');
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ListTile, 'Al-Fatihah'));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pumpAndSettle();
    final arabic = find.byWidgetPredicate(
      (w) => w is SelectableText && (w.data ?? '').contains('بِسْمِ'),
    );
    expect(arabic, findsOneWidget);
    await t.tap(find.byTooltip('Sembunyikan / tampilkan Arab'));
    await t.pumpAndSettle();
    expect(arabic, findsNothing);
    await t.tap(find.byTooltip('Sembunyikan / tampilkan Arab'));
    await t.pumpAndSettle();
    expect(arabic, findsOneWidget);
    await t.tap(find.byType(DropdownButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Abdurrahman As-Sudais').last);
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user.v2'), contains('"qari":"03"'));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
