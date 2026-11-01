import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'quran_repository.dart';

const qaris = {
  '01': 'Abdullah Al-Juhany',
  '02': 'Abdul Muhsin Al-Qasim',
  '03': 'Abdurrahman As-Sudais',
  '04': 'Ibrahim Al-Dossari',
  '05': 'Mishary Rashid Alafasy',
  '06': 'Yasser Al-Dosari',
};

class PlayerController extends ChangeNotifier {
  PlayerController({AudioPlayer Function()? createPlayer})
    : _factory = createPlayer ?? AudioPlayer.new;
  final AudioPlayer Function() _factory;
  AudioPlayer? _engine;
  AudioPlayer get engine => _engine ??= createEngine();
  List<Verse> verses = [];
  int repeats = 1, index = 0, generation = 0;
  bool loading = false, failed = false;
  String qari = '05';
  StreamSubscription<int?>? _indices;
  StreamSubscription<PlayerState>? _states;
  AudioPlayer createEngine() {
    final engine = _factory();
    _indices = engine.currentIndexStream.listen((i) {
      index = i ?? 0;
      notifyListeners();
    });
    _states = engine.playerStateStream.listen((_) {
      notifyListeners();
    });
    return engine;
  }

  Verse? get current => verses.isEmpty ? null : verses[index % verses.length];
  bool get playing =>
      (_engine?.playing ?? false) &&
      _engine?.processingState != ProcessingState.completed;
  static List<Verse> expanded(List<Verse> input, int repeat) => [
    for (var i = 0; i < repeat; i++)
      for (final v in input) v,
  ];
  Future<void> play(List<Verse> input, String voice, int repeat) async {
    if (input.isEmpty) return;
    final token = ++generation;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      await engine.stop();
      final sources = expanded(input, repeat).map((v) {
        final url = v.audio[voice];
        if (url == null) throw StateError('Audio unavailable');
        return AudioSource.uri(Uri.parse(url));
      }).toList();
      if (token != generation) return;
      verses = input;
      repeats = repeat;
      qari = voice;
      index = 0;
      await engine.setAudioSources(sources);
      if (token != generation) return;
      loading = false;
      notifyListeners();
      unawaited(
        engine.play().catchError((Object e) {
          failed = true;
          notifyListeners();
        }),
      );
    } catch (_) {
      if (token == generation) {
        loading = false;
        failed = true;
        notifyListeners();
      }
    }
  }

  Future<void> toggle() async {
    try {
      if (playing) {
        await engine.pause();
      } else {
        if (engine.processingState == ProcessingState.completed) {
          await engine.seek(Duration.zero, index: 0);
        }
        unawaited(
          engine.play().catchError((Object e) {
            failed = true;
            notifyListeners();
          }),
        );
      }
    } catch (_) {
      failed = true;
      notifyListeners();
    }
  }

  Future<void> move(int delta) async {
    try {
      await engine.seek(
        Duration.zero,
        index: (index + delta).clamp(0, verses.length * repeats - 1),
      );
    } catch (_) {
      failed = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    generation++;
    await _engine?.stop();
    failed = false;
    verses = [];
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _indices?.cancel();
    _states?.cancel();
    _engine?.dispose();
    super.dispose();
  }
}
