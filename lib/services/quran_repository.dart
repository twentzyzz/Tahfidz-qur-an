import 'dart:convert';

import 'package:flutter/services.dart';

class Verse {
  Verse(this.surah, this.number, this.arabic, this.translation, this.audio);
  final int surah, number;
  final String arabic, translation;
  final Map<String, String> audio;
  String get ref => '$surah:$number';
}

class Chapter {
  Chapter(this.number, this.name, this.arabic, this.count);
  final int number, count;
  final String name, arabic;
}

/// A matched offline ayah, with the text field(s) that matched the query.
class VerseSearchMatch {
  const VerseSearchMatch({
    required this.verse,
    required this.inArabic,
    required this.inTranslation,
  });

  final Verse verse;
  final bool inArabic, inTranslation;
}

class VerseSearchResults {
  const VerseSearchResults(this.total, this.matches);
  final int total;
  final List<VerseSearchMatch> matches;
}

/// Make Arabic queries forgiving of tashkeel and common alef variants.
/// Indonesian searches are case/whitespace insensitive.
String normalizeVerseSearchText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'[،؛,.!?؟:;()\[\]“”"]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class _SearchableVerse {
  _SearchableVerse(this.verse)
      : arabic = normalizeVerseSearchText(verse.arabic),
        translation = normalizeVerseSearchText(verse.translation);
  final Verse verse;
  final String arabic, translation;
}

class QuranRepository {
  final List<Chapter> chapters = [];
  final List<List<int>> juz = [];
  final Map<int, List<Verse>> _cache = {};
  Future<List<_SearchableVerse>>? _searchIndexFuture;

  Future<List<_SearchableVerse>> _buildSearchIndex() async {
    final index = <_SearchableVerse>[];
    for (final chapter in chapters) {
      for (final verse in await surah(chapter.number)) {
        index.add(_SearchableVerse(verse));
      }
    }
    return index;
  }

  Future<List<_SearchableVerse>> _getSearchIndex() async {
    try {
      return await (_searchIndexFuture ??= _buildSearchIndex());
    } catch (_) {
      // A missing or unreadable asset should not permanently poison retries.
      _searchIndexFuture = null;
      rethrow;
    }
  }

  /// Search all 6236 bundled verses. Results stay in Quran order, and only
  /// [limit] matches are returned to the UI; [VerseSearchResults.total] tells
  /// users how many matches exist so they can narrow a broad search.
  Future<VerseSearchResults> searchVerses(String query, {int limit = 80}) async {
    final needle = normalizeVerseSearchText(query);
    if (needle.isEmpty || limit <= 0) {
      return const VerseSearchResults(0, []);
    }
    final index = await _getSearchIndex();
    final results = <VerseSearchMatch>[];
    var total = 0;
    for (final entry in index) {
      final inArabic = entry.arabic.contains(needle);
      final inTranslation = entry.translation.contains(needle);
      if (!inArabic && !inTranslation) continue;
      total++;
      if (results.length < limit) {
        results.add(VerseSearchMatch(
          verse: entry.verse,
          inArabic: inArabic,
          inTranslation: inTranslation,
        ));
      }
    }
    return VerseSearchResults(total, results);
  }

  Future<void> initialize() async {
    final rows = jsonDecode(
      await rootBundle.loadString('assets/data/surahs.json'),
    ) as List;
    chapters
      ..clear()
      ..addAll(
        rows.map(
          (dynamic s) => Chapter(
            s['nomor'] as int,
            s['namaLatin'] as String,
            s['nama'] as String,
            s['jumlahAyat'] as int,
          ),
        ),
      );
    final bounds =
        jsonDecode(await rootBundle.loadString('assets/data/juz.json')) as List;
    juz
      ..clear()
      ..addAll(
        bounds.map((dynamic b) => <int>[b['surah'] as int, b['ayah'] as int]),
      );
    if (chapters.length != 114 || juz.length != 30) {
      throw const FormatException('Incomplete Quran');
    }
    _cache.clear();
    _searchIndexFuture = null;
  }

  Future<List<Verse>> surah(int number) async {
    if (_cache.containsKey(number)) return _cache[number]!;
    final d = jsonDecode(
      await rootBundle.loadString('assets/data/$number.json'),
    ) as Map;
    final verses = (d['ayat'] as List)
        .map(
          (dynamic a) => Verse(
            number,
            a['nomorAyat'] as int,
            a['teksArab'] as String,
            a['teksIndonesia'] as String,
            Map<String, String>.from(a['audio'] as Map),
          ),
        )
        .toList();
    if (verses.length != chapters[number - 1].count) {
      throw const FormatException('Incomplete verses');
    }
    return _cache[number] = verses;
  }

  /// Returns the juz containing a valid surah/ayah reference, if any.
  /// Juz boundaries come from the verified offline metadata.
  int? juzForVerse(int surahNumber, int verseNumber) {
    if (surahNumber < 1 ||
        surahNumber > chapters.length ||
        verseNumber < 1 ||
        verseNumber > chapters[surahNumber - 1].count ||
        juz.length != 30) {
      return null;
    }
    var result = 1;
    for (var i = 0; i < juz.length; i++) {
      final boundary = juz[i];
      if (surahNumber > boundary[0] ||
          (surahNumber == boundary[0] && verseNumber >= boundary[1])) {
        result = i + 1;
      } else {
        break;
      }
    }
    return result;
  }

  Future<List<Verse>> juzVerses(int number) async {
    final start = juz[number - 1], end = number == 30 ? [115, 1] : juz[number];
    final result = <Verse>[];
    for (var s = start[0]; s <= end[0] && s <= 114; s++) {
      result.addAll(
        (await surah(s)).where(
          (v) =>
              (s != start[0] || v.number >= start[1]) &&
              (s != end[0] || v.number < end[1]),
        ),
      );
    }
    return result;
  }
}
