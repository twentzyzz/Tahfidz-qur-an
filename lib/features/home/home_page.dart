import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/page_layout.dart';
import '../surah/surah_list_page.dart';
import '../tahfidz/tahfidz_page.dart';
import '../progress/progress_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => PageLayout(
    title: 'Tahfidz Quran',
    children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.emerald,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFFFFD887),
              size: 40,
            ),
            SizedBox(height: 24),
            Text(
              'Assalamu’alaikum',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Langkah kecil,\nhafalan bermakna.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Bangun kebiasaan bersama Al-Qur’an, setiap hari.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Text('Ruang belajar Anda', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      _Destination(
        icon: Icons.menu_book_rounded,
        title: 'Daftar Surah',
        subtitle: 'Temukan surah untuk dipelajari',
        page: const SurahListPage(),
      ),
      _Destination(
        icon: Icons.repeat_rounded,
        title: 'Mulai Menghafal',
        subtitle: 'Siapkan sesi tahfidz Anda',
        page: const TahfidzPage(),
      ),
      _Destination(
        icon: Icons.insights_rounded,
        title: 'Progres Hafalan',
        subtitle: 'Ruang untuk perjalanan hafalan Anda',
        page: const ProgressPage(),
      ),
      const SizedBox(height: 20),
      const Text(
        'Tahap awal • Data ayat dan audio belum terhubung.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, color: AppColors.emerald),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page)),
    ),
  );
}
