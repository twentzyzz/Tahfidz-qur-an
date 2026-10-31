import '../models/ayah.dart';
import '../models/surah.dart';

/// Implementasi jaringan berikutnya dapat menggunakan endpoint ini.
abstract class QuranService {
  static const baseUrl = 'https://equran.id/api/v2';
  Future<List<Surah>> getSurahs();
  Future<List<Ayah>> getAyahs(int surahNumber);
}

/// Metadata awal yang nyata, bukan katalog lengkap atau data ayat.
class QuranCatalog {
  const QuranCatalog();
  static const surahs = <Surah>[
    Surah(number: 1, name: 'Al-Fatihah', verseCount: 7),
    Surah(number: 2, name: 'Al-Baqarah', verseCount: 286),
    Surah(number: 18, name: 'Al-Kahf', verseCount: 110),
    Surah(number: 36, name: 'Yasin', verseCount: 83),
    Surah(number: 55, name: 'Ar-Rahman', verseCount: 78),
    Surah(number: 67, name: 'Al-Mulk', verseCount: 30),
    Surah(number: 114, name: 'An-Nas', verseCount: 6),
  ];

  List<Surah> search(String query) {
    final value = query.trim().toLowerCase();
    return surahs
        .where(
          (s) =>
              s.name.toLowerCase().contains(value) ||
              s.number.toString() == value,
        )
        .toList();
  }
}
