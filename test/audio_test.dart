import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tahfidz_quran/services/player_controller.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

class FakePlayer implements AudioPlayer {
  @override
  bool playing = false;
  @override
  ProcessingState processingState = ProcessingState.ready;
  List<AudioSource> sources = [];
  int seekIndex = 0;
  @override
  Duration position = Duration.zero;
  @override
  Duration? get duration => const Duration(seconds: 30);
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    int? initialIndex,
    Duration? initialPosition,
    bool preload = true,
    ShuffleOrder? shuffleOrder,
  }) async {
    this.sources = sources;
    seekIndex = initialIndex ?? 0;
    position = initialPosition ?? Duration.zero;
    return Duration.zero;
  }

  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> stop() async {
    playing = false;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seekIndex = index ?? seekIndex;
    this.position = position ?? Duration.zero;
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Audio controller loads real URLs, changes qari, pauses, seeks, stops',
    () async {
      final q = QuranRepository();
      await q.initialize();
      final verses = (await q.surah(1)).take(2).toList();
      final engine = FakePlayer(),
          p = PlayerController(createPlayer: () => engine);
      await p.play(verses, '05', 3);
      expect(engine.sources.length, 6);
      expect(
        (engine.sources.first as UriAudioSource).uri.toString(),
        verses.first.audio['05'],
      );
      expect(p.playing, true);
      await p.toggle();
      expect(p.playing, false);
      await p.move(1);
      expect(engine.seekIndex, 1);
      await p.play(verses, '03', 1);
      expect(
        (engine.sources.first as UriAudioSource).uri.toString(),
        verses.first.audio['03'],
      );
      await p.seek(const Duration(seconds: 8));
      expect(engine.position, const Duration(seconds: 8));
      await p.toggle(); // pause before switching voices
      p.index = 1;
      await p.changeQari('06');
      expect(engine.seekIndex, 1);
      expect(engine.position, const Duration(seconds: 8));
      expect(p.playing, false);
      expect(
        (engine.sources.first as UriAudioSource).uri.toString(),
        verses.first.audio['06'],
      );
      await p.changeRepeats(5);
      expect(engine.sources.length, 10);
      expect(engine.seekIndex, 1);
      expect(p.playing, false);
      await p.play(verses, 'invalid', 1);
      expect(p.failed, true);
      await p.stop();
      expect(p.current, isNull);
      p.dispose();
    },
  );
}
