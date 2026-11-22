import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/features/progress/detailed_stats_page.dart';
import 'package:tahfidz_quran/features/progress/progress_page.dart';
import 'package:tahfidz_quran/features/surah/reading_catalog.dart';
import 'package:tahfidz_quran/features/surah/verse_search_page.dart';
import 'package:tahfidz_quran/features/tahfidz/tahfidz_page.dart';
import 'package:tahfidz_quran/features/tahfidz/verse_quiz_page.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/memorization_stats.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';
import 'package:tahfidz_quran/services/verse_quiz.dart';
import 'package:tahfidz_quran/services/verse_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('search and quiz do not change stored memorization progress', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    addTearDown(store.dispose);

    await store.mark('1:1', 'done', at: DateTime(2026, 11, 20));
    final before = store.map('progress');
    final verses = <Verse>[
      Verse(1, 1, 'بِسْمِ اللَّهِ', 'Dengan nama Allah', {}),
      Verse(1, 2, 'الرَّحْمَٰنِ', 'Maha Pengasih', {}),
      Verse(1, 3, 'الْحَمْدُ', 'Segala puji', {}),
      Verse(1, 4, 'الرَّحِيمِ', 'Maha Penyayang', {}),
      Verse(1, 5, 'الْعَالَمِينَ', 'Seluruh alam', {}),
      Verse(1, 6, 'مَالِكِ', 'Pemilik', {}),
    ];
    expect(VerseSearch.filter(verses, 'pengasih').single.ref, '1:2');
    final quiz = VerseQuiz.generate(verses, random: Random(7));
    expect(quiz, hasLength(5));
    expect(quiz.every((q) => q.options.where(q.isCorrect).length == 1), isTrue);
    expect(store.map('progress'), before);
    expect(MemorizationStats(store, now: DateTime(2026, 11, 21)).memorized, 1);
  });

  test('three feature entry points and screens are available in the app', () {
    expect(const ReadingCatalog(), isA<StatefulWidget>());
    expect(const VerseSearchPage(), isA<StatefulWidget>());
    expect(const TahfidzPage(), isA<StatelessWidget>());
    expect(const VerseQuizPage(), isA<StatefulWidget>());
    expect(const ProgressPage(), isA<StatelessWidget>());
    expect(const DetailedStatsPage(), isA<StatelessWidget>());
  });
}
