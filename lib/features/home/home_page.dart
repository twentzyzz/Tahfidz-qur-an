import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import '../../services/player_controller.dart';

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/mini_player.dart';
import '../surah/surah_list_page.dart';
import '../surah/surah_detail_page.dart';
import '../tahfidz/tahfidz_page.dart';
import '../progress/progress_page.dart';
import '../prayer/prayer_page.dart';
import '../settings/settings_page.dart';
import '../qari/qari_page.dart';

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
    if (mounted) {
      Session.of(context).prayer.schedule().catchError((Object _) {});
    }
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

  void open(Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext c) {
    final labels = [
      c.t('Beranda', 'Home'),
      c.t('Al-Qur’an', 'Quran'),
      '30 Juz',
      c.t('Hafalan', 'Memorize'),
      c.t('Progres', 'Progress'),
    ];
    const outline = AppIcons.navigation;
    const selected = AppIcons.selectedNavigation;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index == 0) ...[
              SizedBox.square(
                dimension: 38,
                child: Image.asset(
                  'assets/branding/logo.png',
                  cacheWidth: (38 * MediaQuery.devicePixelRatioOf(c)).ceil(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                index == 0 ? 'Tahfidz Quran' : labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: c.t('Notifikasi salat', 'Prayer notifications'),
            onPressed: () => open(const SettingsPage()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: c.t('Pengaturan', 'Settings'),
            onPressed: () => open(const SettingsPage()),
            icon: const Icon(AppIcons.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: [
          _Dashboard(
            onSurahs: () => setState(() => index = 1),
            onJuz: () => setState(() => index = 2),
            onMemorize: () => setState(() => index = 3),
            onProgress: () => setState(() => index = 4),
            onQari: () => open(const QariPage()),
            onPrayer: () => open(const PrayerPage()),
            onResume: (surah, verse) => open(
              SurahDetailPage(
                number: surah,
                initialVerse: verse,
                memorize: true,
              ),
            ),
            onDetail: (surah, verse) =>
                open(SurahDetailPage(number: surah, initialVerse: verse)),
          ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return _CompactBottomNavigation(
                  labels: labels,
                  outline: outline,
                  selected: selected,
                  index: index,
                  onSelected: (i) => setState(() => index = i),
                );
              }
              return NavigationBar(
                height: 74,
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: index,
                onDestinationSelected: (i) => setState(() => index = i),
                destinations: [
                  for (var i = 0; i < 5; i++)
                    NavigationDestination(
                      icon: Icon(outline[i]),
                      selectedIcon: Icon(selected[i]),
                      label: labels[i],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.onSurahs,
    required this.onJuz,
    required this.onMemorize,
    required this.onProgress,
    required this.onQari,
    required this.onPrayer,
    required this.onDetail,
    required this.onResume,
  });
  final VoidCallback onSurahs, onJuz, onMemorize, onProgress, onQari, onPrayer;
  final void Function(int, int) onDetail, onResume;

  @override
  Widget build(BuildContext context) {
    final s = Session.of(context);
    final cs = Theme.of(context).colorScheme;
    final done = s.store
        .map('progress')
        .values
        .where((v) => v == 'done')
        .length;
    final last = s.store.map('last');
    final memo = s.store.map('lastMemorization');
    final hasMemo = memo['surah'] is int && memo['verse'] is int;
    final chapter = hasMemo
        ? s.quran.chapters[(memo['surah'] as int) - 1]
        : null;
    final chapterDone = chapter == null
        ? 0
        : s.store
              .map('progress')
              .entries
              .where(
                (e) =>
                    e.key.startsWith('${chapter.number}:') && e.value == 'done',
              )
              .length;
    final bookmarks = s.store.map('bookmarks').keys.toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              context.t('Assalamu’alaikum', 'Assalamu alaikum'),
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                'Temukan ritme hafalanmu.',
                'Find your memorization rhythm.',
              ),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.4),
            ),
            const SizedBox(height: 8),
            Text(
              MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                color: AppColors.darkEmerald,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('LANJUTKAN HAFALAN', 'CONTINUE MEMORIZING'),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter?.name ??
                        context.t(
                          'Satu ayat, satu langkah.',
                          'One verse, one step.',
                        ),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasMemo
                        ? '${context.t('Ayat', 'Verse')} ${memo['verse']} · $chapterDone / ${chapter!.count} ${context.t('ayat hafal', 'memorized')}'
                        : context.t(
                            'Bangun kebiasaan baik, mulai dari ayat pertama.',
                            'Build a gentle habit, starting with the first verse.',
                          ),
                    style: const TextStyle(
                      color: Color(0xFFD5E8DF),
                      height: 1.5,
                    ),
                  ),
                  if (chapter != null) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: chapterDone / chapter.count,
                      color: AppColors.gold,
                      backgroundColor: Colors.white24,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.darkEmerald,
                    ),
                    onPressed: hasMemo
                        ? () => onResume(
                            memo['surah'] as int,
                            memo['verse'] as int,
                          )
                        : onMemorize,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      hasMemo
                          ? context.t('Lanjutkan', 'Continue')
                          : context.t('Mulai Menghafal', 'Start memorizing'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.t('Akses cepat', 'Quick access'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.menu_book_rounded,
                    title: context.t('Daftar Surah', 'Surah list'),
                    onTap: onSurahs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.auto_stories_rounded,
                    title: '30 Juz',
                    onTap: onJuz,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.headphones_rounded,
                    title: context.t('Audio Murottal', 'Quran audio'),
                    onTap: onQari,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.bookmark_border_rounded,
                    title: context.t('Latihan Hafalan', 'Memorize'),
                    onTap: onMemorize,
                  ),
                ),
              ],
            ),
            if (last['surah'] is int && last['verse'] is int) ...[
              const SizedBox(height: 22),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.bookmark_added_outlined),
                  title: Text(
                    context.t('Lanjutkan Bacaan', 'Continue reading'),
                  ),
                  subtitle: Text(
                    '${s.quran.chapters[(last['surah'] as int) - 1].name} • ${context.t('Ayat', 'Verse')} ${last['verse']}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () =>
                      onDetail(last['surah'] as int, last['verse'] as int),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.t(
                              'Progres Hafalan',
                              'Memorization progress',
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${(done / 6236 * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: done / 6236,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$done / 6236 ${context.t('ayat sudah hafal', 'verses memorized')}',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onProgress,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          context.t('Lihat progres', 'View progress'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.t('Salat berikutnya', 'Next prayer'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const PrayerSummary(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPrayer,
                child: Text(
                  context.t(
                    'Jadwal & checklist salat',
                    'Prayer schedule & checklist',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('Qari Pilihan', 'Featured reciters'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final id in ['05', '06', '03'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: QariAvatar(name: qaris[id]!),
                title: Text(qaris[id]!),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onQari,
              ),
            const SizedBox(height: 20),
            Text(
              context.t('Bookmark ayat', 'Verse bookmarks'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (bookmarks.isEmpty)
              Text(
                context.t(
                  'Belum ada bookmark. Ketuk ikon bookmark saat membaca.',
                  'No bookmarks yet. Tap the bookmark icon while reading.',
                ),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            for (final ref in bookmarks.take(5))
              ListTile(
                title: Text(
                  '${s.quran.chapters[int.parse(ref.split(':')[0]) - 1].name} • ${ref.split(':')[1]}',
                ),
                leading: const Icon(Icons.bookmark_outline_rounded),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onDetail(
                  int.parse(ref.split(':')[0]),
                  int.parse(ref.split(':')[1]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBottomNavigation extends StatelessWidget {
  const _CompactBottomNavigation({
    required this.labels,
    required this.outline,
    required this.selected,
    required this.index,
    required this.onSelected,
  });

  final List<String> labels;
  final List<IconData> outline, selected;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('compact-bottom-navigation'),
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == i,
                    label: labels[i],
                    child: InkWell(
                      onTap: () => onSelected(i),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: index == i
                                    ? colors.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                index == i ? selected[i] : outline[i],
                                size: 24,
                                color: index == i
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: index == i
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: index == i
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
