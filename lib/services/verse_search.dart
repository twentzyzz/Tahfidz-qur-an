import 'quran_repository.dart';

/// Text search is performed against the bundled, verified Quran verses.
class VerseSearch {
  static final _arabicMarks = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final _spaces = RegExp(r'\s+');

  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(_arabicMarks, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  static bool matches(Verse verse, String query) {
    final needle = normalize(query);
    if (needle.isEmpty) return false;
    return normalize(verse.arabic).contains(needle) ||
        normalize(verse.translation).contains(needle);
  }

  static List<Verse> filter(Iterable<Verse> verses, String query) {
    final needle = normalize(query);
    if (needle.isEmpty) return const [];
    return verses.where((v) => matches(v, needle)).toList();
  }
}
