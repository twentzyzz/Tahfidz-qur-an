import 'dart:async';
import 'dart:io';

import 'package:tahfidz_quran/services/offline_recitation/worker.dart';
import 'package:tahfidz_quran/services/offline_recitation/device_native.dart'
    show verifyModelFile;

import 'package:tahfidz_quran/services/offline_recitation/text_metrics.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/services/offline_recitation/controller.dart';
import 'package:tahfidz_quran/services/offline_recitation/domain.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

final sampleVerses = [
  Verse(1, 1, 'بِسْمِ ٱللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', '', {}),
];

class FakeRecitationDevice implements RecitationDevice {
  bool denied = false,
      recording = false,
      removed = false,
      failInference = false;
  Completer<RecognitionResult>? pending;
  Completer<void>? permission;
  @override
  bool get supported => true;
  @override
  Future<void> prepare() async {}
  @override
  Future<void> startRecording() async {
    await permission?.future;
    if (denied) throw const RecitationFailure('permissionDenied');
    recording = true;
  }

  @override
  Future<String?> stopRecording() async {
    recording = false;
    return 'private.wav';
  }

  @override
  Future<void> playRecording(String path) async {}
  @override
  Future<void> stopPlayback() async {}
  @override
  Future<void> removeRecording(String path) async {
    removed = true;
  }

  @override
  Future<void> dispose() async {
    recording = false;
  }

  @override
  Future<RecognitionResult> recognize(String path) async {
    if (failInference) throw StateError('Out of memory');
    return pending != null
        ? pending!.future
        : const RecognitionResult(
            text: 'بسم الله الرحمن الرحيم',
            model: 'test',
          );
  }
}

void main() {
  test(
    'Oversized waveform is rejected before native model initialization',
    () async {
      final dir = await Directory.systemTemp.createTemp('recitation-size-');
      try {
        final file = File('${dir.path}/oversized.wav');
        await file.writeAsBytes(List<int>.filled(1024 * 1024 + 1, 0));
        expect(
          recognizeWhisper('/missing-model', file.path).reason,
          'invalidAudio',
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test('Model verification rejects missing or corrupted assets', () async {
    final dir = await Directory.systemTemp.createTemp('recitation-hash-');
    const hash =
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
    final file = File('${dir.path}/model');
    try {
      expect(await verifyModelFile(file.path, hash), isFalse);
      await file.writeAsString('abc');
      expect(await verifyModelFile(file.path, hash), isTrue);
      await file.writeAsString('damaged');
      expect(await verifyModelFile(file.path, hash), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('WER/CER distance counts insertions, omissions and substitutions', () {
    expect(editDistance(['a', 'b', 'c'], ['a', 'd', 'c', 'e']), 2);
    expect(editDistance('رحمة'.runes.toList(), 'رحمه'.runes.toList()), 1);
    expect(editDistance(<String>[], ['extra']), 1);
  });

  test('Arabic normalization preserves meaningful consonant differences', () {
    expect(normalizeArabic('بِسْمِ ٱللَّهِ'), 'بسم الله');
    expect(normalizeArabic('رَحْمَٰن'), 'رحمن');
    expect(normalizeArabic('ا\u0654'), 'أ');
    expect(normalizeArabic('أ إ آ ة ى'), 'أ إ آ ة ى');
    expect(normalizeArabic('أنت'), isNot(normalizeArabic('انت')));
    expect(normalizeArabic('رحمة'), isNot(normalizeArabic('رحمه')));
  });
  test(
    'Alignment maps missing, extra and differing words to verse positions',
    () {
      final verses = [
        Verse(1, 1, 'بسم الله', '', {}),
        Verse(1, 2, 'الرحمن الرحيم', '', {}),
      ];
      final result = alignRecitation(
        verses,
        const RecognitionResult(
          text: 'بسم الله الرحيم',
          model: 'validated-test',
          qualityValidated: true,
        ),
      );
      expect(result.status, RecitationStatus.needsReview);
      expect(result.differences.single.kind, 'missing');
      expect(result.differences.single.reference!.ref, '1:2');
      expect(result.differences.single.reference!.index, 1);
      final extra = alignRecitation(
        verses,
        const RecognitionResult(
          text: 'بسم الله الله الرحمن الرحيم',
          model: 'test',
          qualityValidated: true,
        ),
      );
      expect(extra.differences.single.kind, 'extra');
      final different = alignRecitation(
        verses,
        const RecognitionResult(
          text: 'بسم الله الرحمن الكريم',
          model: 'test',
          qualityValidated: true,
        ),
      );
      expect(different.differences.single.kind, 'different');
    },
  );
  test(
    'Uncalibrated model never produces a verdict or word-level accusations',
    () {
      for (final text in ['بسم الله الرحمن الرحيم', 'كلام مختلف تماما']) {
        final result = alignRecitation(
          sampleVerses,
          RecognitionResult(text: text, model: 'tiny'),
        );
        expect(result.status, RecitationStatus.unassessed);
        expect(result.differences, isEmpty);
      }
      expect(
        alignRecitation(
          sampleVerses,
          const RecognitionResult(text: '', model: 'test', reason: 'silence'),
        ).reason,
        'silence',
      );
      expect(
        alignRecitation(
          sampleVerses,
          const RecognitionResult(text: '', model: 'test'),
        ).status,
        RecitationStatus.unassessed,
      );
    },
  );
  test('Explicitly validated test result can match; no percentage score is created', () {
    expect(
      alignRecitation(
        sampleVerses,
        const RecognitionResult(
          text: 'بسم الله الرحمن الرحيم',
          model: 'test',
          qualityValidated: true,
        ),
      ).status,
      RecitationStatus.detectedMatch,
    );
  });
  test(
    'Permission rejection leaves manual recovery possible without recording',
    () async {
      final device = FakeRecitationDevice()..denied = true;
      final controller = RecitationController(device, sampleVerses);
      await controller.prepare();
      await controller.start();
      expect(controller.error, 'permissionDenied');
      expect(device.recording, isFalse);
      expect(controller.phase, RecitationPhase.ready);
      controller.dispose();
    },
  );
  test('Controller pipeline deletes temporary audio after result or inference failure', () async {
    for (final fail in [false, true]) {
      final device = FakeRecitationDevice()..failInference = fail;
      final controller = RecitationController(device, sampleVerses);
      await controller.prepare();
      await controller.start();
      await controller.stop();
      await controller.process();
      expect(device.removed, isTrue);
      expect(controller.clip, isNull);
      expect(
        controller.phase,
        fail ? RecitationPhase.error : RecitationPhase.result,
      );
      controller.dispose();
    }
  });
  test(
    'Cancel pending native inference discards late result and cleans audio',
    () async {
      final device = FakeRecitationDevice()
        ..pending = Completer<RecognitionResult>();
      final controller = RecitationController(device, sampleVerses);
      await controller.prepare();
      await controller.start();
      await controller.stop();
      final processing = controller.process();
      await Future<void>.delayed(Duration.zero);
      final cancellation = controller.cancel();
      expect(controller.phase, RecitationPhase.cancelling);
      device.pending!.complete(
        const RecognitionResult(text: 'late result', model: 'test'),
      );
      await processing;
      await cancellation;
      expect(controller.recognition, isNull);
      expect(device.removed, isTrue);
      expect(controller.phase, RecitationPhase.ready);
      controller.dispose();
    },
  );
  test(
    'Cancel while permission prompt is pending stops late microphone startup',
    () async {
      final device = FakeRecitationDevice()..permission = Completer<void>();
      final controller = RecitationController(device, sampleVerses);
      await controller.prepare();
      final starting = controller.start();
      final cancellation = controller.cancel();
      device.permission!.complete();
      await starting;
      await cancellation;
      expect(device.recording, isFalse);
      expect(device.removed, isTrue);
      expect(controller.phase, RecitationPhase.ready);
      controller.dispose();
    },
  );
}
