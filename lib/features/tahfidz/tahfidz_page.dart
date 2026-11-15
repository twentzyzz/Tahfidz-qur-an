import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../l10n/app_strings.dart';
import 'review_page.dart';
import '../surah/surah_list_page.dart';

class TahfidzPage extends StatelessWidget {
  const TahfidzPage({super.key});
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkEmerald, AppColors.emerald],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_stories_rounded, color: Color(0xFFF0D49A), size: 34),
              const SizedBox(height: 14),
              Text(
                c.t('Jaga hafalan, satu ayat setiap hari', 'Build your memorization, one verse a day'),
                style: Theme.of(c).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                c.t('Pilih surah, tentukan rentang ayat, dengarkan, lalu ulangi sesuai ritmemu.',
                  'Choose a surah, select a verse range, listen, then repeat at your own pace.'),
                style: const TextStyle(color: Color(0xFFE1EEE7), height: 1.5),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFB6D8C7)),
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute<void>(builder: (_) => const ReviewPage()),
                ),
                icon: const Icon(Icons.event_repeat),
                label: Text(c.t('Murajaah terjadwal', 'Scheduled review')),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(c.t('Pilih surah untuk memulai', 'Choose a surah to begin'),
            style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
      const Expanded(child: SurahListPage(memorize: true)),
    ],
  );
}
