import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';
import 'package:tahfidz_quran/services/verse_search.dart';

void main() {
  final verses = <Verse>[
    Verse(1, 1, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.', {}),
    Verse(1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'Segala puji bagi Allah, Tuhan seluruh alam.', {}),
  ];

  test('Arabic input without harakat matches verse with harakat', () {
    expect(VerseSearch.filter(verses, 'الرحمن').map((v) => v.ref), ['1:1']);
  });

  test('Indonesian text matches ignoring letter case', () {
    expect(VerseSearch.filter(verses, 'MAHA PENGASIH').map((v) => v.ref),
        ['1:1']);
  });

  test('Empty query does not return every verse', () {
    expect(VerseSearch.filter(verses, '   '), isEmpty);
  });

  test('Unmatched term returns empty results', () {
    expect(VerseSearch.filter(verses, 'kata-tidak-ada'), isEmpty);
  });
}
