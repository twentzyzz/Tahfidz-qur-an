import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
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
import '../notifications/notifications_page.dart';
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
        toolbarHeight: 68 +
            (MediaQuery.textScalerOf(c).scale(20) - 20).clamp(0, 80) * 2,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index == 0 &&
                MediaQuery.sizeOf(c).width >= 380 &&
                MediaQuery.textScalerOf(c).scale(16) <= 20) ...[
              SizedBox.square(
                dimension: 38,
                child: Image.asset(
                  'assets/branding/logo.png',
                  cacheWidth: (38 * MediaQuery.devicePixelRatioOf(c)).ceil(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                index == 0 ? 'Tahfidz Quran' : labels[index],
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: c.t('Notifikasi salat', 'Prayer notifications'),
            onPressed: () => open(const NotificationsPage()),
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
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
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _CompactBottomNavigation(
            labels: labels,
            outline: outline,
            selected: selected,
            index: index,
            onSelected: (i) => setState(() => index = i),
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
          key: const PageStorageKey('home-dashboard-phase-two'),
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
            24,
            MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
            32,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: cs.primary.withValues(alpha: .17),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 15, color: cs.primary),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        context.t('Assalamu’alaikum', 'Assalamu alaikum'),
                        softWrap: true,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.t(
                'Setiap ayat, satu langkah lebih dekat',
                'One verse, one step closer',
              ),
              key: const Key('home-greeting-headline'),
              softWrap: true,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -.8,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              key: const Key('home-premium-hero'),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF064735),
                    Color(0xFF08674C),
                    Color(0xFF123D32),
                  ],
                ),
                border: Border.all(color: AppColors.gold, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkEmerald.withValues(alpha: .18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -56,
                    top: -70,
                    child: IgnorePointer(
                      child: Container(
                        width: 204,
                        height: 204,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: .25),
                            width: 1.3,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 147,
                            height: 147,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.goldLight.withValues(alpha: .14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: -28,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.goldLight.withValues(alpha: .07),
                        size: 95,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFF4D28A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.t('PERJALANAN HAFALAN', 'MEMORIZATION JOURNEY'),
                                  softWrap: true,
                                  style: const TextStyle(fontSize: 10, letterSpacing: .4, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.menu_book_rounded, color: Color(0xFFE0C98E), size: 27),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('Hafalan hari ini', 'Today’s memorization'),
                    style: const TextStyle(
                      color: Color(0xFFD5E8DF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter?.name ??
                        context.t(
                          'Mulai dari satu ayat',
                          'Begin with one verse',
                        ),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasMemo
                        ? '${context.t('Ayat', 'Verse')} ${memo['verse']} · $chapterDone / ${chapter!.count} ${context.t('ayat hafal', 'memorized')}'
                        : context.t(
                            'Pilih surah, dengarkan, lalu ulangi sesuai ritmemu.',
                            'Choose a surah, listen, and repeat at your own pace.',
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
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: .33),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 16, color: AppColors.goldLight),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '$done / 6236 ${context.t('ayat hafal', 'verses memorized')}',
                                softWrap: true,
                                maxLines: 3,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldLight,
                      foregroundColor: AppColors.darkEmerald,
                      minimumSize: const Size(148, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: hasMemo
                        ? () => onResume(
                            memo['surah'] as int,
                            memo['verse'] as int,
                          )
                        : onMemorize,
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    label: Text(
                      hasMemo
                          ? context.t('Lanjutkan', 'Continue')
                          : context.t('Mulai Menghafal', 'Start memorizing'),
                    ),
                  ),
                    ],
                  ),
                ],
              ),
            ),
            if (last['surah'] is int && last['verse'] is int) ...[
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('home-continue-reading'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.bookmark_added_rounded, color: cs.primary),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: cs.primary),
                  title: Text(
                    context.t('Lanjutkan Bacaan', 'Continue reading'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${s.quran.chapters[(last['surah'] as int) - 1].name} • ${context.t('Ayat', 'Verse')} ${last['verse']}',
                  ),
                  onTap: () =>
                      onDetail(last['surah'] as int, last['verse'] as int),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('Baca & dengarkan', 'Read & listen'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              context.t(
                'Pilih aktivitas untuk menemani hafalanmu.',
                'Choose a way to read, listen or practice.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final singleColumn = constraints.maxWidth < 275 ||
                    MediaQuery.textScalerOf(context).scale(16) > 25;
                const gap = 12.0;
                final width = singleColumn
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: _Shortcut(
                        icon: Icons.menu_book_rounded,
                        title: context.t('Daftar Surah', 'Surah list'),
                        subtitle: context.t('114 surah untuk dibaca', 'Explore 114 surahs'),
                        tone: 0,
                        onTap: onSurahs,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _Shortcut(
                        icon: Icons.library_books_rounded,
                        title: '30 Juz',
                        subtitle: context.t('Jelajahi tiap juz', 'Explore each juz'),
                        tone: 1,
                        onTap: onJuz,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _Shortcut(
                        icon: Icons.headphones_rounded,
                        title: context.t('Audio Murottal', 'Quran audio'),
                        subtitle: context.t('Dengarkan qari pilihan', 'Listen to your reciter'),
                        tone: 2,
                        onTap: onQari,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _Shortcut(
                        icon: Icons.psychology_rounded,
                        title: context.t('Latihan Hafalan', 'Memorize'),
                        subtitle: context.t('Ulang dan kuatkan hafalan', 'Practice and remember'),
                        tone: 3,
                        onTap: onMemorize,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          context.t(
                            'Progres Hafalan',
                            'Memorization progress',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                      child: TextButton(
                        onPressed: onProgress,
                        child: Text(
                          context.t('Lihat progres', 'View progress'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.mosque_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.t('Salat berikutnya', 'Next prayer'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const PrayerSummary(),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onPrayer,
                        child: Text(
                          context.t(
                            'Jadwal & checklist salat',
                            'Prayer schedule & checklist',
                          ),
                          softWrap: true,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.headphones_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('Qari Pilihan', 'Featured reciters'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final id in ['05', '06', '03'])
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: QariAvatar(name: qaris[id]!),
                      title: Text(
                        qaris[id]!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: cs.primary),
                      onTap: onQari,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.bookmark_outline_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('Bookmark ayat', 'Verse bookmarks'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: bookmarks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_outlined,
                              color: cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.t(
                                'Belum ada bookmark. Ketuk ikon bookmark saat membaca.',
                                'No bookmarks yet. Tap the bookmark icon while reading.',
                              ),
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (final ref in bookmarks.take(5))
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Icon(Icons.bookmark_rounded,
                                color: cs.primary),
                            title: Text(
                              '${s.quran.chapters[int.parse(ref.split(':')[0]) - 1].name} • ${ref.split(':')[1]}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_outward_rounded,
                                color: cs.primary, size: 19),
                            onTap: () => onDetail(
                              int.parse(ref.split(':')[0]),
                              int.parse(ref.split(':')[1]),
                            ),
                          ),
                      ],
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
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark
        ? (tone.isEven
            ? const Color(0xFF203C32)
            : const Color(0xFF352F24))
        : (tone.isEven
            ? const Color(0xFFEAF5EF)
            : const Color(0xFFFFF4E1));
    final accent = dark
        ? AppColors.goldLight
        : tone.isEven
            ? AppColors.darkEmerald
            : const Color(0xFF85632E);

    return Material(
      key: ValueKey('home-shortcut-$tone'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, Color.lerp(tint, cs.surface, .68)!],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: dark ? cs.outlineVariant : AppColors.goldBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 154),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: dark ? .14 : .85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: .15),
                          ),
                        ),
                        child: Icon(icon, size: 24, color: accent),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_outward_rounded,
                          color: accent, size: 18),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      height: 1.25,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(12) > 16 &&
                constraints.maxWidth < 600;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: colors.outlineVariant),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            Expanded(
                              child: Semantics(
                                key: ValueKey('navigation-semantics-$i'),
                                button: true,
                                selected: index == i,
                                label: labels[i],
                                onTap: () => onSelected(i),
                                excludeSemantics: true,
                                child: Tooltip(
                                  message: labels[i],
                                  child: InkWell(
                                    key: ValueKey('navigation-$i'),
                                    onTap: () => onSelected(i),
                                    borderRadius: BorderRadius.circular(14),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minHeight: 56),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              width: index == i ? 25 : 8,
                                              height: 3,
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: index == i
                                                    ? AppColors.gold
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            AnimatedContainer(
                                              key: ValueKey('navigation-icon-$i'),
                                              duration: const Duration(milliseconds: 180),
                                              curve: Curves.easeOutCubic,
                                              width: 46,
                                              height: 36,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                gradient: index == i
                                                    ? const LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          AppColors.darkEmerald,
                                                          AppColors.emerald,
                                                        ],
                                                      )
                                                    : null,
                                                borderRadius: BorderRadius.circular(13),
                                                border: index == i
                                                    ? Border.all(
                                                        color: AppColors.gold.withValues(alpha: .75),
                                                      )
                                                    : null,
                                                boxShadow: index == i
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.darkEmerald.withValues(alpha: .16),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Icon(
                                                index == i ? selected[i] : outline[i],
                                                size: 23,
                                                color: index == i
                                                    ? AppColors.goldLight
                                                    : colors.onSurfaceVariant,
                                              ),
                                            ),
                                            if (!largeText) ...[
                                              const SizedBox(height: 5),
                                              Text(
                                                labels[i],
                                                maxLines: 2,
                                                textAlign: TextAlign.center,
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  height: 1.12,
                                                  fontWeight: index == i ? FontWeight.w800 : FontWeight.w600,
                                                  color: index == i ? colors.primary : colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (largeText)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
