// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tahfidz_quran/services/audio_offline_service.dart';
import 'package:tahfidz_quran/services/player_controller.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

import 'audio_test.dart' show FakePlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Downloads use local audio, skip existing files and allow deletion',
      () async {
    final temp = await Directory.systemTemp.createTemp('tahfidz_audio_');
    addTearDown(() => temp.delete(recursive: true));
    final q = QuranRepository();
    await q.initialize();
    final verses = (await q.surah(1)).take(2).toList();
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.url.host, 'cdn.equran.id');
      return http.Response('ID3' + 'A' * 120, 200,
          headers: {'content-type': 'audio/mpeg'});
    });
    final offline = AudioOfflineService(
      client: client,
      directoryProvider: () async => temp,
    );
    addTearDown(offline.dispose);
    await offline.downloadSurah(verses, '05');
    expect(requests, 2);
    expect(offline.completed, 2);
    expect((await offline.snapshot('05')).countFor(1), 2);
    expect((await offline.cachedUri(verses.first, '05'))?.scheme, 'file');
    await offline.downloadSurah(verses, '05');
    expect(requests, 2);

    final fake = FakePlayer();
    final player = PlayerController(
      createPlayer: () => fake,
      offlineAudio: offline,
    );
    await player.play(verses, '05', 1);
    expect((fake.sources.first as UriAudioSource).uri.scheme, 'file');
    await offline.deleteSurah(1, '05');
    expect((await offline.snapshot('05')).countFor(1), 0);
    await player.play(verses, '05', 1);
    expect((fake.sources.first as UriAudioSource).uri.toString(),
        verses.first.audio['05']);
    await player.stop();
    player.dispose();
    client.close();
  });

  test('HTTP failures never leave a playable partial file', () async {
    final temp = await Directory.systemTemp.createTemp('tahfidz_fail_');
    addTearDown(() => temp.delete(recursive: true));
    final q = QuranRepository();
    await q.initialize();
    final verse = (await q.surah(1)).first;
    final offline = AudioOfflineService(
      client: MockClient((_) async => http.Response('missing', 404)),
      directoryProvider: () async => temp,
    );
    addTearDown(offline.dispose);
    await expectLater(offline.downloadSurah([verse], '05'),
        throwsA(isA<HttpException>()));
    expect(offline.isDownloading, false);
    expect(await offline.cachedUri(verse, '05'), isNull);
    expect((await offline.snapshot('05')).countFor(1), 0);
  });

  test('Cancel keeps cache free of unfinished audio', () async {
    final temp = await Directory.systemTemp.createTemp('tahfidz_cancel_');
    addTearDown(() => temp.delete(recursive: true));
    final q = QuranRepository();
    await q.initialize();
    final verses = (await q.surah(1)).take(2).toList();
    final offline = AudioOfflineService(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response('ID3' + 'A' * 120, 200,
            headers: {'content-type': 'audio/mpeg'});
      }),
      directoryProvider: () async => temp,
    );
    addTearDown(offline.dispose);
    final loading = offline.downloadSurah(verses, '05');
    offline.cancel();
    await loading;
    expect(offline.isDownloading, false);
    expect((await offline.snapshot('05')).countFor(1), 0);
  });
}
