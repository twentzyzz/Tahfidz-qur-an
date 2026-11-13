// CLI smoke test of the exact native worker used by Android. This is not a
// substitute for an Android microphone/emulator/physical-device test.
import 'dart:io';

import 'package:tahfidz_quran/services/offline_recitation/worker.dart';

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: dart run tool/probe_offline_recognizer.dart MODEL_DIRECTORY MONO_16KHZ_WAV',
    );
  }
  final watch = Stopwatch()..start();
  final result = recognizeWhisper(args[0], args[1]);
  stdout.writeln(
    'model=${result.model}; elapsedMs=${watch.elapsedMilliseconds}; reason=${result.reason}; qualityValidated=${result.qualityValidated}',
  );
  stdout.writeln(result.text);
}
