import 'package:flutter/material.dart';

import '../../models/surah.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/empty_state.dart';
import '../tahfidz/tahfidz_page.dart';

class SurahDetailPage extends StatelessWidget {
  const SurahDetailPage({super.key, required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) => PageLayout(
    title: surah.name,
    children: [
      Text(
        'Surah ${surah.number} • ${surah.verseCount} ayat',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Ayat belum tersedia',
        message: 'Teks ayat dan terjemahan akan dimuat dari EQuran.id pada tahap berikutnya.',
      ),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.headphones_rounded, size: 32),
              SizedBox(height: 12),
              Text('Audio murottal'),
              SizedBox(height: 8),
              Text(
                'Pilihan qari, pemutaran, dan pengulangan ayat belum tersedia.',
                textAlign: TextAlign.center,
              ),
              IconButton(
                onPressed: null,
                tooltip: 'Audio belum tersedia',
                icon: Icon(Icons.play_circle_outline),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        icon: const Icon(Icons.repeat),
        label: const Text('Siapkan hafalan'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TahfidzPage(initialSurah: surah),
          ),
        ),
      ),
    ],
  );
}
