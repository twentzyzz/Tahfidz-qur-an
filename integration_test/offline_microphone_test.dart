// Grant RECORD_AUDIO before this test (see docs/OFFLINE_RECITATION.md).
// An emulator validates the Android recording pipeline, not real speech quality.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:record/record.dart';
import 'package:tahfidz_quran/services/offline_recitation/device.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android records, plays, processes and deletes a private clip', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final permissionProbe = AudioRecorder();
    try {
      expect(
        await permissionProbe.hasPermission(request: false),
        isTrue,
        reason:
            'Install the debug APK and grant RECORD_AUDIO before this test. '
            'Use --no-uninstall for the preceding native test; see '
            'docs/OFFLINE_RECITATION.md.',
      );
    } finally {
      await permissionProbe.dispose();
    }
    final device = createRecitationDevice();
    String? clip;
    try {
      expect(device.supported, isTrue);
      await device.prepare();
      debugPrint('Microphone test: model prepared');
      await device.startRecording();
      debugPrint('Microphone test: recording started');
      await Future<void>.delayed(const Duration(seconds: 2));
      clip = await device.stopRecording();
      expect(clip, isNotNull);
      expect(await File(clip!).length(), greaterThan(44));
      debugPrint('Microphone test: WAV recorded');
      await device.playRecording(clip).timeout(const Duration(seconds: 30));
      debugPrint('Microphone test: playback completed');
      await device.stopPlayback();
      final result = await device.recognize(clip);
      debugPrint('Microphone test: local processing completed');
      expect(result.qualityValidated, isFalse);
      expect(result.model, 'whisper-tiny-int8-sherpa-2024-07-13');
    } finally {
      await device.stopRecording();
      await device.stopPlayback();
      if (clip != null) await device.removeRecording(clip);
      await device.dispose();
    }
    expect(await File(clip).exists(), isFalse);
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(minutes: 8)));
}
