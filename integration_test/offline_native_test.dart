// Android smoke test: real bundled model and native decode, synthetic input.
// Does not establish Quran accuracy or physical microphone performance.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tahfidz_quran/main.dart' as app;
import 'package:tahfidz_quran/services/offline_recitation/device.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android bundled model processes audio locally and releases resources',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Mulai Menghafal'), findsOneWidget);
      final device = createRecitationDevice();
      expect(device.supported, isTrue);
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/native-smoke.wav');
      try {
        await device.prepare();
        const count = 32000;
        final bytes = ByteData(44 + count * 2);
        void ascii(int offset, String value) {
          for (var i = 0; i < value.length; i++) {
            bytes.setUint8(offset + i, value.codeUnitAt(i));
          }
        }

        ascii(0, 'RIFF');
        bytes.setUint32(4, 36 + count * 2, Endian.little);
        ascii(8, 'WAVE');
        ascii(12, 'fmt ');
        bytes.setUint32(16, 16, Endian.little);
        bytes.setUint16(20, 1, Endian.little);
        bytes.setUint16(22, 1, Endian.little);
        bytes.setUint32(24, 16000, Endian.little);
        bytes.setUint32(28, 32000, Endian.little);
        bytes.setUint16(32, 2, Endian.little);
        bytes.setUint16(34, 16, Endian.little);
        ascii(36, 'data');
        bytes.setUint32(40, count * 2, Endian.little);
        for (var i = 0; i < count; i++) {
          bytes.setInt16(
            44 + i * 2,
            (3000 * sin(2 * pi * 440 * i / 16000)).round(),
            Endian.little,
          );
        }
        await file.writeAsBytes(bytes.buffer.asUint8List());
        final result = await device.recognize(file.path);
        expect(result.model, 'whisper-tiny-int8-sherpa-2024-07-13');
        expect(result.qualityValidated, isFalse);
        // Tone passes the amplitude gate; the real decoder must run. Its output
        // may be empty/hallucinated and cannot be treated as speech correctness.
        expect(result.reason, anyOf(isNull, 'emptyTranscript'));
      } finally {
        await device.removeRecording(file.path);
        await device.dispose();
      }
      expect(await file.exists(), isFalse);
      // Exercise the real Android navigation and asset preparation as well as
      // the native decoder. This does not request microphone permission.
      await tester.tap(find.text('Mulai Menghafal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Al-Fatihah');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Al-Fatihah'));
      await tester.pumpAndSettle();
      final entry = find.text('Latihan dengan AI Offline');
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('AI Koreksi Hafalan Offline'), findsOneWidget);
      expect(find.text('Mulai rekam'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(entry, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
