import 'dart:math';
import 'dart:io';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'recognition.dart';

const offlineModelId = 'whisper-tiny-int8-sherpa-2024-07-13';

/// Runs inside an isolate, never on the Flutter UI thread. No HTTP client.
RecognitionResult recognizeWhisper(String directory, String wavPath) {
  if (File(wavPath).lengthSync() > 1024 * 1024) {
    return const RecognitionResult(
      text: '',
      model: offlineModelId,
      reason: 'invalidAudio',
    );
  }
  sherpa.initBindings();
  final wave = sherpa.readWave(wavPath);
  if (wave.sampleRate != 16000 ||
      wave.samples.length < 11200 ||
      wave.samples.length > 336000) {
    return const RecognitionResult(
      text: '',
      model: offlineModelId,
      reason: 'invalidAudio',
    );
  }
  var energy = 0.0, clipped = 0;
  for (final sample in wave.samples) {
    energy += sample * sample;
    if (sample.abs() > 0.98) clipped++;
  }
  if (sqrt(energy / wave.samples.length) < 0.008) {
    return const RecognitionResult(
      text: '',
      model: offlineModelId,
      reason: 'silence',
    );
  }
  if (clipped / wave.samples.length > 0.1) {
    return const RecognitionResult(
      text: '',
      model: offlineModelId,
      reason: 'clipped',
    );
  }
  final recognizer = sherpa.OfflineRecognizer(
    sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: '$directory/tiny-encoder.int8.onnx',
          decoder: '$directory/tiny-decoder.int8.onnx',
          language: 'ar',
          task: 'transcribe',
        ),
        tokens: '$directory/tiny-tokens.txt',
        modelType: 'whisper',
        numThreads: 2,
        debug: false,
      ),
    ),
  );
  sherpa.OfflineStream? stream;
  try {
    stream = recognizer.createStream();
    stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
    recognizer.decode(stream);
    final result = recognizer.getResult(stream);
    return RecognitionResult(
      text: result.text,
      model: offlineModelId,
      reason: result.text.trim().isEmpty ? 'emptyTranscript' : null,
    );
  } finally {
    stream?.free();
    recognizer.free();
  }
}
