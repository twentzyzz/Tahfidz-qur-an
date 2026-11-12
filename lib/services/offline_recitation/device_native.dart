import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'domain.dart';
import 'worker.dart';

const modelHashes = {
  'tiny-encoder.int8.onnx':
      'd24fb083ae3b1041fc24e97971d60e280c9342201fbb67b0ab428a8b4a51a434',
  'tiny-decoder.int8.onnx':
      'd2fece8dd42771f1df975c6c0445770d0c292bf7547c2cae04a6c0cc57540925',
  'tiny-tokens.txt':
      'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
};
Future<bool> verifyModelFile(String path, String hash) async {
  if (!await File(path).exists()) return false;
  return (await sha256.bind(File(path).openRead()).first).toString() == hash;
}

RecitationDevice createRecitationDevice() => AndroidRecitationDevice();

class AndroidRecitationDevice implements RecitationDevice {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  String? _models, _path;
  @override
  bool get supported => Platform.isAndroid;
  @override
  Future<void> prepare() async {
    if (!supported) throw const RecitationFailure('unsupported');
    final support = await getApplicationSupportDirectory();
    final models = Directory('${support.path}/$offlineModelId');
    await models.create(recursive: true);
    for (final entry in modelHashes.entries) {
      final path = '${models.path}/${entry.key}';
      if (await Isolate.run(() => verifyModelFile(path, entry.value))) continue;
      try {
        final bytes = await rootBundle.load(
          'assets/models/whisper_tiny/${entry.key}',
        );
        final staged = File('$path.tmp');
        await staged.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        if (!await Isolate.run(
          () => verifyModelFile(staged.path, entry.value),
        )) {
          await staged.delete();
          throw const RecitationFailure('modelCorrupt');
        }
        await staged.rename(path);
      } on RecitationFailure {
        rethrow;
      } catch (_) {
        throw const RecitationFailure('modelMissing');
      }
    }
    _models = models.path;
    final temporary = await getTemporaryDirectory();
    final recordings = Directory('${temporary.path}/offline-recitation');
    await recordings.create(recursive: true);
    // Crash recovery: this private directory contains only disposable recordings.
    await for (final entity in recordings.list()) {
      if (entity is File) await entity.delete();
    }
    _path = '${recordings.path}/session.wav';
  }

  @override
  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw const RecitationFailure('permissionDenied');
    }
    if (_path == null) throw const RecitationFailure('modelMissing');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
      path: _path!,
    );
  }

  @override
  Future<String?> stopRecording() => _recorder.stop();
  @override
  Future<void> playRecording(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> stopPlayback() => _player.stop();
  @override
  Future<void> removeRecording(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<RecognitionResult> recognize(String wavPath) async {
    final models = _models;
    if (models == null) throw const RecitationFailure('modelMissing');
    return Isolate.run(() => recognizeWhisper(models, wavPath));
  }

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
    final path = _path;
    if (path != null) await removeRecording(path);
  }
}
