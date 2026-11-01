import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common.dart';
import '../../widgets/mini_player.dart';
import '../surah/surah_list_page.dart';
import '../surah/surah_detail_page.dart';
import '../tahfidz/tahfidz_page.dart';
import '../progress/progress_page.dart';
import '../prayer/prayer_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int index = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => reschedule());
  }

  void reschedule() {
    if (mounted) perform(context, () => Session.of(context).prayer.schedule());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reschedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final s = Session.of(c);
    final last = s.store.map('last');
    final labels = [
      c.t('Beranda', 'Home'),
      c.t("Al-Qur’an", 'Quran'),
      '30 Juz',
      c.t('Hafalan', 'Memorize'),
      c.t('Progres', 'Progress'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'Tahfidz Quran' : labels[index]),
        actions: [
          IconButton(
            tooltip: c.t('Ibadah 5 Waktu', 'Daily prayers'),
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute<void>(builder: (_) => const PrayerPage()),
            ),
            icon: const Icon(Icons.mosque),
          ),
          IconButton(
            tooltip: c.t('Pengaturan', 'Settings'),
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: [
          padded([
            Card(
              color: Theme.of(c).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/branding/logo.png', height: 70),
                    const SizedBox(height: 16),
                    Text(
                      c.t('Assalamu’alaikum', 'Assalamu alaikum'),
                      style: Theme.of(c).textTheme.headlineSmall,
                    ),
                    Text(
                      c.t(
                        'Langkah kecil, hafalan bermakna.',
                        'Small steps, meaningful memorization.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => setState(() => index = 3),
              child: Text(c.t('Mulai Menghafal', 'Start memorizing')),
            ),
            OutlinedButton(
              onPressed: () => setState(() => index = 1),
              child: Text(c.t('Daftar Surah', 'Surah list')),
            ),
            if (last.isNotEmpty)
              FilledButton.tonal(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute<void>(
                    builder: (_) => SurahDetailPage(
                      number: last['surah'] as int,
                      initialVerse: last['verse'] as int,
                    ),
                  ),
                ),
                child: Text(c.t('Lanjutkan Bacaan', 'Continue reading')),
              ),
            ListTile(
              title: Text(c.t('Progres Hafalan', 'Memorization progress')),
              subtitle: Text(
                '${s.store.map('progress').values.where((v) => v == 'done').length} / 6236',
              ),
              onTap: () => setState(() => index = 4),
            ),
            const PrayerSummary(),
            Text(
              c.t('Bookmark ayat', 'Verse bookmarks'),
              style: Theme.of(c).textTheme.titleLarge,
            ),
            if (s.store.map('bookmarks').isEmpty)
              Text(
                c.t(
                  'Belum ada bookmark. Ketuk ikon bookmark saat membaca.',
                  'No bookmarks yet. Tap the bookmark icon while reading.',
                ),
              ),
            for (final ref in s.store.map('bookmarks').keys)
              ListTile(
                title: Text(
                  '${s.quran.chapters[int.parse(ref.split(':')[0]) - 1].name} • ${ref.split(':')[1]}',
                ),
                onTap: () => Navigator.push(
                  c,
                  MaterialPageRoute<void>(
                    builder: (_) => SurahDetailPage(
                      number: int.parse(ref.split(':')[0]),
                      initialVerse: int.parse(ref.split(':')[1]),
                    ),
                  ),
                ),
              ),
          ]),
          const SurahListPage(),
          const JuzPage(),
          const TahfidzPage(),
          const ProgressPage(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: [
              for (var i = 0; i < 5; i++)
                NavigationDestination(
                  icon: Icon(
                    [
                      Icons.home_outlined,
                      Icons.menu_book,
                      Icons.library_books,
                      Icons.repeat,
                      Icons.insights,
                    ][i],
                  ),
                  label: labels[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
