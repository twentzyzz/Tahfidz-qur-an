import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/models/ayah.dart';
import 'package:tahfidz_quran/models/surah.dart';
import 'package:tahfidz_quran/services/quran_service.dart';

void main() {
  test('Catalog searches name case-insensitively and exact surah number', () {
    const catalog = QuranCatalog();
    expect(catalog.search('  AL-MULK ').single.number, 67);
    expect(catalog.search('114').single.name, 'An-Nas');
    expect(catalog.search('').length, 7);
    expect(catalog.search('xyz'), isEmpty);
    expect(QuranCatalog.surahs.map((s) => s.number).toSet().length, 7);
  });

  test('Models accept EQuran v2 field names, including optional audio', () {
    final surah = Surah.fromEquranJson({
      'nomor': 1,
      'namaLatin': 'Al-Fatihah',
      'jumlahAyat': 7,
    });
    expect(surah.verseCount, 7);
    // Empty strings test decoding only, never fabricate Quran text.
    final ayah = Ayah.fromEquranJson({
      'nomorAyat': 1,
      'teksArab': '',
      'teksIndonesia': '',
    });
    expect(ayah.number, 1);
    expect(ayah.audioByQari, isEmpty);
  });
}
