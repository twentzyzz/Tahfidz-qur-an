import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/app.dart';
import 'package:tahfidz_quran/models/surah.dart';

void main() {
  testWidgets('Search, open surah, prepare tahfidz, and navigate back', (
    tester,
  ) async {
    await tester.pumpWidget(const TahfidzApp());
    await tester.tap(find.text('Daftar Surah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mulk');
    await tester.pumpAndSettle();
    expect(find.text('Al-Mulk'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsNothing);
    await tester.tap(find.text('Al-Mulk'));
    await tester.pumpAndSettle();
    expect(find.text('Ayat belum tersedia'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Audio belum tersedia',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Siapkan hafalan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilihan Anda: Al-Mulk • 30 ayat'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pumpAndSettle();
    expect(find.text('Surah tidak ditemukan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Progres Hafalan'), 150);
    await tester.tap(find.text('Progres Hafalan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada progres tersimpan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tahfidz selection works from home on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TahfidzApp());
    await tester.scrollUntilVisible(find.text('Mulai Menghafal'), 150);
    await tester.tap(find.text('Mulai Menghafal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Surah>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Al-Fatihah').last);
    await tester.pumpAndSettle();
    expect(find.text('Pilihan Anda: Al-Fatihah • 7 ayat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home fits a large text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const TahfidzApp());
    await tester.pumpAndSettle();
    expect(find.text('Tahfidz Quran'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
