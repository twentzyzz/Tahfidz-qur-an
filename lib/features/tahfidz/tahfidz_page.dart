import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../l10n/app_strings.dart';
import 'review_page.dart';
import 'verse_quiz_page.dart';
import '../surah/surah_list_page.dart';

class TahfidzPage extends StatelessWidget {
  const TahfidzPage({super.key});
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkEmerald, AppColors.emerald],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Color(0xFFF0D49A), size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.t('Hafalkan satu ayat hari ini', 'Memorize one verse today'),
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute<void>(builder: (_) => const ReviewPage()),
            ),
            icon: const Icon(Icons.event_repeat),
            label: Text(c.t('Murajaah terjadwal', 'Scheduled review')),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('open-verse-quiz'),
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute<void>(
                builder: (_) => const VerseQuizPage(),
              ),
            ),
            icon: const Icon(Icons.quiz_outlined),
            label: Text(c.t('Kuis Sambung Ayat', 'Next Verse Quiz')),
          ),
        ),
      ),
      const Expanded(child: SurahListPage(memorize: true)),
    ],
  );
}
