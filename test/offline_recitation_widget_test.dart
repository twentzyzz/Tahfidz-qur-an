import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/offline_recitation/offline_recitation_page.dart';

import 'widget_test.dart' show boot;
import 'offline_recitation_test.dart' show FakeRecitationDevice, sampleVerses;

void main() {
  testWidgets('Microphone denial is visible and retry remains available', (
    t,
  ) async {
    await boot(t);
    final c = t.element(find.byType(Scaffold).first);
    Navigator.of(c).push(
      MaterialPageRoute<void>(
        builder: (_) => OfflineRecitationPage(
          verses: sampleVerses,
          device: FakeRecitationDevice()..denied = true,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(FilledButton, 'Mulai rekam'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mulai rekam'));
    await t.pumpAndSettle();
    expect(find.textContaining('Izin mikrofon ditolak'), findsOneWidget);
    expect(find.text('Mulai rekam'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets(
    'Offline recording, processing and explicit summary consent; no transcript persisted',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await boot(t);
      final c = t.element(find.byType(Scaffold).first),
          device = FakeRecitationDevice();
      final s = Session.of(c);
      Navigator.of(c).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              OfflineRecitationPage(verses: sampleVerses, device: device),
        ),
      );
      await t.pumpAndSettle();
      Future<void> tap(String text) async {
        await t.ensureVisible(find.text(text));
        await t.pumpAndSettle();
        await t.tap(find.text(text));
        await t.pumpAndSettle();
      }

      await tap('Mulai rekam');
      expect(device.recording, isTrue);
      await tap('Hentikan rekaman');
      await tap('Proses offline');
      expect(find.text('Belum dapat dinilai'), findsOneWidget);
      expect(device.removed, isTrue);
      expect(s.store.data['offlineRecitationSessions'], isNull);
      await t.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Simpan ringkasan'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Simpan ringkasan'));
      await t.pumpAndSettle();
      final summaries = s.store.data['offlineRecitationSessions'] as List;
      expect(summaries, hasLength(1));
      expect(summaries.single['status'], 'unassessed');
      expect(summaries.single.containsKey('text'), isFalse);
      expect(summaries.single.containsKey('audio'), isFalse);
      expect(s.store.map('progress'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
}
