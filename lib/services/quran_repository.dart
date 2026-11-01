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

class QuranRepository {
  final List<Chapter> chapters = [];
  final List<List<int>> juz = [];
  final Map<int, List<Verse>> _cache = {};
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
