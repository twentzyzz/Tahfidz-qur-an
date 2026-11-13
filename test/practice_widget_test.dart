import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/progress/practice_calendar.dart';
import 'package:tahfidz_quran/features/tahfidz/practice_page.dart';
import 'package:tahfidz_quran/features/tahfidz/review_page.dart';
import 'package:tahfidz_quran/services/practice_store.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets(
    'Exam only presents selected verses and saves manual results once',
    (t) async {
      await boot(t);
      final context = t.element(find.byType(Scaffold).first);
      final navigator = Navigator.of(context);
      final s = Session.of(context);
      final verses = (await t.runAsync(() => s.quran.surah(1)))!;
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PracticePage(verses: verses.sublist(1, 3)),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Mulai ujian'));
      await t.pumpAndSettle();
      expect(find.text('Al-Fatihah • 2'), findsOneWidget);
      expect(find.text(verses[1].arabic), findsNothing);
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text('Tampilkan jawaban'));
        await t.pumpAndSettle();
        expect(find.text(verses[i + 1].arabic), findsOneWidget);
        await t.ensureVisible(find.text('Lancar'));
        await t.tap(find.text('Lancar'));
        await t.pumpAndSettle();
      }
      expect(find.text('Ringkasan latihan'), findsOneWidget);
      expect(s.store.data['practiceSessions'], isNull);
      await t.ensureVisible(find.widgetWithText(FilledButton, 'Simpan hasil'));
      await t.pumpAndSettle();
      await t.tap(find.text('Simpan hasil'));
      await t.pumpAndSettle();
      expect(find.text('Hasil tersimpan'), findsOneWidget);
      final sessions = s.store.data['practiceSessions'] as List;
      expect(sessions, hasLength(1));
      expect(sessions.single['ratings'], {'1:2': 'fluent', '1:3': 'fluent'});
      expect(s.store.map('progress'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Cancel unsaved exam leaves history unchanged', (t) async {
    await boot(t);
    final context = t.element(find.byType(Scaffold).first);
    final navigator = Navigator.of(context);
    final s = Session.of(context);
    final verses = (await t.runAsync(() => s.quran.surah(1)))!;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePage(verses: [verses.first]),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Mulai ujian'));
    await t.pumpAndSettle();
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    expect(find.text('Keluar dari latihan?'), findsOneWidget);
    await t.tap(find.text('Keluar'));
    await t.pumpAndSettle();
    expect(find.byType(PracticePage), findsNothing);
    expect(s.store.data['practiceSessions'], isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Calendar and review empty state fit narrow screens with large text',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(t);
      final context = t.element(find.byType(Scaffold).first);
      final navigator = Navigator.of(context);
      final s = Session.of(context);
      await s.store.changeDailyGoal(1);
      await s.store.mark('1:1', 'done');
      await s.store.mark('1:1', 'none');
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const PracticeCalendar()),
      );
      await t.pumpAndSettle();
      expect(find.text('Target: 1 / 1 — Tercapai'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const ReviewPage()),
      );
      await t.pumpAndSettle();
      expect(find.text('0 ayat perlu diulang'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Continue mode shows the preceding selected verse as a hint', (
    t,
  ) async {
    await boot(t);
    final context = t.element(find.byType(Scaffold).first);
    final navigator = Navigator.of(context);
    final s = Session.of(context);
    final verses = (await t.runAsync(() => s.quran.surah(1)))!;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePage(verses: verses.sublist(1, 3)),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Sambung ayat').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Mulai ujian'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tampilkan jawaban'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Lancar'));
    await t.tap(find.text('Lancar'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Lanjutkan setelah ayat ini:'));
    expect(find.text(verses[1].arabic), findsOneWidget);
    expect(find.text(verses[2].arabic), findsNothing);
    expect(find.text('Al-Fatihah • 3'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Saving a due review removes it from the due list', (t) async {
    await boot(t);
    final context = t.element(find.byType(Scaffold).first);
    final navigator = Navigator.of(context);
    final s = Session.of(context);
    await s.store.mark(
      '1:1',
      'done',
      at: DateTime.now().subtract(const Duration(days: 2)),
    );
    navigator.push(MaterialPageRoute<void>(builder: (_) => const ReviewPage()));
    await t.pumpAndSettle();
    expect(find.text('1 ayat perlu diulang'), findsOneWidget);
    await t.tap(find.text('Al-Fatihah • 1'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mulai ujian'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tampilkan jawaban'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Lancar'));
    await t.tap(find.text('Lancar'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(FilledButton, 'Simpan hasil'));
    await t.pumpAndSettle();
    await t.tap(find.text('Simpan hasil'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(TextButton, 'Selesai'));
    await t.pumpAndSettle();
    await t.tap(find.text('Selesai'));
    await t.pumpAndSettle();
    expect(find.text('0 ayat perlu diulang'), findsOneWidget);
    expect(s.store.map('progress')['1:1'], 'done');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
