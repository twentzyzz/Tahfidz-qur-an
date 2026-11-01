import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';
import 'package:tahfidz_quran/services/player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '114 surahs contain all 6236 verses, Arabic, translation and six reciters',
    () async {
      final q = QuranRepository();
      await q.initialize();
      expect(q.chapters.length, 114);
      var count = 0;
      for (final c in q.chapters) {
        final verses = await q.surah(c.number);
        expect(verses.length, c.count);
        expect(
          verses.map((v) => v.number),
          List.generate(c.count, (i) => i + 1),
        );
        for (final v in verses) {
          expect(v.arabic, isNotEmpty);
          expect(v.translation, isNotEmpty);
          expect(v.audio.keys.toSet(), qaris.keys.toSet());
          for (final url in v.audio.values) {
            expect(Uri.parse(url).scheme, 'https');
            expect(Uri.parse(url).host, 'cdn.equran.id');
          }
        }
        count += verses.length;
      }
      expect(count, 6236);
    },
  );
  test(
    '30 juz cover every verse once in Quran order with verified boundaries',
    () async {
      final q = QuranRepository();
      await q.initialize();
      final refs = <String>[];
      for (var i = 1; i <= 30; i++) {
        final v = await q.juzVerses(i);
        expect(v.first.ref, '${q.juz[i - 1][0]}:${q.juz[i - 1][1]}');
        refs.addAll(v.map((v) => v.ref));
      }
      final expected = <String>[];
      for (var i = 1; i <= 114; i++) {
        expected.addAll((await q.surah(i)).map((v) => v.ref));
      }
      expect(refs, expected);
      expect(refs.toSet().length, 6236);
      expect(q.juz[1], [2, 142]);
      expect(q.juz.last, [78, 1]);
    },
  );
  test('Repeats preserve verse range order for 1,3,5,10 rounds', () async {
    final q = QuranRepository();
    await q.initialize();
    final range = (await q.surah(1)).sublist(1, 3);
    for (final n in [1, 3, 5, 10]) {
      expect(PlayerController.expanded(range, n).map((v) => v.ref), [
        for (var i = 0; i < n; i++) ...['1:2', '1:3'],
      ]);
    }
  });
}
