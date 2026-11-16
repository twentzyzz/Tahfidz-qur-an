import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:tahfidz_quran/services/player_controller.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

import 'audio_test.dart' show FakePlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All repeated verses carry distinct metadata for background controls',
      () async {
    final quran = QuranRepository();
    await quran.initialize();
    final verses = (await quran.surah(1)).take(2).toList();
    final fake = FakePlayer();
    final controller = PlayerController(createPlayer: () => fake);
    await controller.play(verses, '05', 3, autoplay: false);
    expect(fake.sources.length, 6);
    final tags = fake.sources
        .map((source) => (source as UriAudioSource).tag as MediaItem)
        .toList();
    expect(tags.map((item) => item.id).toSet().length, 6);
    expect(tags.first.title, 'Ayat 1');
    expect(tags.first.album, 'Tahfidz Quran • Surah 1');
    expect(tags.first.artist, 'Mishary Rashid Alafasy');
    expect(tags[2].title, 'Ayat 1');
    expect(tags[2].id, isNot(tags[0].id));
    await controller.changeQari('06');
    expect(
      ((fake.sources.first as UriAudioSource).tag as MediaItem).artist,
      'Yasser Al-Dosari',
    );
    await controller.stop();
    controller.dispose();
  });
}
