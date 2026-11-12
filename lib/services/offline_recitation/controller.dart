import 'dart:async';

import 'package:flutter/foundation.dart';

import '../quran_repository.dart';
import 'domain.dart';

enum RecitationPhase {
  preparing,
  ready,
  starting,
  recording,
  recorded,
  processing,
  cancelling,
  result,
  error,
}

class RecitationController extends ChangeNotifier {
  RecitationController(this.device, this.verses);
  final RecitationDevice device;
  final List<Verse> verses;
  RecitationPhase phase = RecitationPhase.preparing;
  String? error, clip;
  RecognitionResult? recognition;
  AlignmentResult? alignment;
  int seconds = 0, _generation = 0;
  bool _disposed = false;
  Timer? _timer;
  Future<void>? _operation, _recordOperation, _prepareOperation, _cancelling;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> prepare() => _prepareOperation = _prepare();

  Future<void> _prepare() async {
    phase = RecitationPhase.preparing;
    error = null;
    _notify();
    try {
      await device.prepare();
      phase = RecitationPhase.ready;
    } catch (e) {
      error = e is RecitationFailure ? e.code : 'unavailable';
      phase = RecitationPhase.error;
    }
    _notify();
  }

  Future<void> start() => _recordOperation = _start();

  Future<void> _start() async {
    if (phase != RecitationPhase.ready) return;
    phase = RecitationPhase.starting;
    error = null;
    seconds = 0;
    _notify();
    final generation = ++_generation;
    try {
      await device.startRecording();
      if (_disposed || generation != _generation) {
        final path = await device.stopRecording();
        if (path != null) await device.removeRecording(path);
        return;
      }
      phase = RecitationPhase.recording;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        _notify();
        if (seconds >= 20) unawaited(stop());
      });
    } catch (e) {
      error = e is RecitationFailure ? e.code : 'recordingFailed';
      phase = RecitationPhase.ready;
    }
    _notify();
  }

  Future<void> stop() => _recordOperation = _stop();

  Future<void> _stop() async {
    if (phase != RecitationPhase.recording) return;
    _timer?.cancel();
    phase = RecitationPhase.starting;
    _notify();
    try {
      clip = await device.stopRecording();
      if (clip == null) throw const RecitationFailure('recordingFailed');
      phase = RecitationPhase.recorded;
    } catch (_) {
      error = 'recordingFailed';
      phase = RecitationPhase.ready;
    }
    _notify();
  }

  Future<void> play() async {
    final path = clip;
    if (phase != RecitationPhase.recorded || path == null) return;
    try {
      await device.playRecording(path);
    } catch (_) {
      error = 'playbackFailed';
      _notify();
    }
  }

  Future<void> process() async {
    if (phase != RecitationPhase.recorded || clip == null) return;
    final generation = ++_generation;
    phase = RecitationPhase.processing;
    error = null;
    _notify();
    _operation = _process(generation);
    await _operation;
  }

  Future<void> _process(int generation) async {
    final path = clip!;
    try {
      await device.stopPlayback();
      final result = await device.recognize(path);
      if (_disposed || generation != _generation) return;
      recognition = result;
      alignment = alignRecitation(verses, result);
      phase = RecitationPhase.result;
    } catch (e) {
      if (generation == _generation) {
        error = e is RecitationFailure ? e.code : 'inferenceFailed';
        phase = RecitationPhase.error;
      }
    } finally {
      try {
        await device.removeRecording(path);
        clip = null;
      } catch (_) {
        error = 'deleteFailed';
      }
      _notify();
    }
  }

  Future<void> cancel() =>
      _cancelling ??= _cancel().whenComplete(() => _cancelling = null);

  Future<void> _cancel() async {
    ++_generation;
    _timer?.cancel();
    final old = phase;
    phase = RecitationPhase.cancelling;
    _notify();
    try {
      await _prepareOperation;
      await _recordOperation;
      await device.stopPlayback();
      if (old == RecitationPhase.recording) {
        clip = await device.stopRecording() ?? clip;
      }
      // Native decode cannot be interrupted safely. Wait for its finally block
      // to free native model/stream, discard its result, then allow another run.
      await _operation;
      if (clip != null) await device.removeRecording(clip!);
      clip = null;
      recognition = null;
      alignment = null;
      error = null;
      phase = RecitationPhase.ready;
    } catch (_) {
      error = 'deleteFailed';
      phase = RecitationPhase.error;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(cancel().whenComplete(device.dispose).catchError((Object _) {}));
    super.dispose();
  }
}
