import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_strings.dart';
import '../../services/practice_store.dart';
import '../../widgets/common.dart';
import '../surah/surah_list_page.dart';
import 'practice_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool loading = false;

  Future<void> openMemorization() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (c) => Scaffold(
          appBar: AppBar(title: Text(c.t('Pilih surah hafalan', 'Choose a surah'))),
          body: const SurahListPage(memorize: true),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> openPractice(String ref) async {
    if (loading) return;
    final session = Session.of(context);
    setState(() => loading = true);
    await perform(context, () async {
      final parts = ref.split(':').map(int.parse).toList();
      final verses = await session.quran.surah(parts[0]);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PracticePage(
            verses: [verses[parts[1] - 1]],
            review: true,
          ),
        ),
      );
    });
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) {
    final session = Session.of(c);
    final colors = Theme.of(c).colorScheme;
    final progress = session.store.map('progress');
    final reviews = session.store.map('reviews');
    final due = session.store.dueReviews(DateTime.now());
    final memorized = progress.values.where((v) => v == 'done').length;
    final dueSet = due.toSet();
    final upcoming = reviews.entries.where((entry) =>
        progress[entry.key] == 'done' &&
        !dueSet.contains(entry.key) &&
        entry.value is Map &&
        (entry.value as Map)['due'] is String).toList()
      ..sort((a, b) => (a.value as Map)['due'].toString().compareTo(
          (b.value as Map)['due'].toString()));

    String verseTitle(String ref) {
      final parts = ref.split(':');
      final chapter = session.quran.chapters[int.parse(parts[0]) - 1];
      return '${chapter.name} • ${c.t('Ayat', 'Verse')} ${parts[1]}';
    }

    String dueDate(String date) {
      final parsed = DateTime.tryParse(date);
      return parsed == null
          ? date
          : MaterialLocalizations.of(c).formatMediumDate(parsed);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c.t('Murajaah', 'Review')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            key: const PageStorageKey('review-dashboard'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF064735), Color(0xFF087454), Color(0xFF123D32)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkEmerald.withValues(alpha: .16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.goldLight,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            c.t('PERJALANAN HAFALAN', 'MEMORIZATION JOURNEY'),
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      c.t('Jaga hafalan, setiap hari', 'Keep your memorization strong'),
                      style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      memorized == 0
                          ? c.t(
                              'Mulai dari satu ayat. Jadwal murajaah akan terbentuk saat ayat ditandai sudah hafal.',
                              'Start with one verse. Your review schedule starts when you mark a verse as memorized.',
                            )
                          : c.t(
                              'Ulangi ayat sesuai jadwal agar hafalan tetap terjaga.',
                              'Review verses on schedule to keep your memorization fresh.',
                            ),
                      style: const TextStyle(
                        color: Color(0xFFE2F1E9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: .23)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _HeroStat(
                              value: '${due.length}',
                              label: c.t('Perlu diulang', 'Due today'),
                            ),
                          ),
                          Container(
                            height: 42,
                            width: 1,
                            color: Colors.white.withValues(alpha: .23),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: _HeroStat(
                                value: '$memorized',
                                label: c.t('Ayat sudah hafal', 'Memorized verses'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _ReviewHeading(
                icon: Icons.today_rounded,
                title: c.t('Murajaah hari ini', "Today's review"),
                count: due.length,
              ),
              const SizedBox(height: 12),
              if (loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              if (due.isEmpty)
                Card(
                  key: const Key('murajaah-empty'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            memorized == 0
                                ? Icons.menu_book_rounded
                                : Icons.task_alt_rounded,
                            size: 33,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          memorized == 0
                              ? c.t('Belum ada jadwal murajaah', 'No reviews scheduled yet')
                              : c.t('Hafalan hari ini terjaga', 'All caught up for today'),
                          textAlign: TextAlign.center,
                          style: Theme.of(c).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memorized == 0
                              ? c.t(
                                  'Pilih surah, hafalkan ayat, lalu tandai “Sudah hafal”. Ayat tersebut akan masuk jadwal pengulangan.',
                                  'Choose a surah, memorize a verse, then mark it as memorized. It will appear in your review schedule.',
                                )
                              : c.t(
                                  'Tidak ada ayat yang harus diulang sekarang. Kamu bisa melanjutkan hafalan atau melihat jadwal berikutnya.',
                                  'No verses need reviewing right now. You can keep memorizing or check the upcoming schedule.',
                                ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('murajaah-start-memorization'),
                            onPressed: openMemorization,
                            icon: const Icon(Icons.auto_stories_rounded),
                            label: Text(c.t('Mulai hafalan', 'Start memorizing')),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final ref in due)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        key: ValueKey('murajaah-due-$ref'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.repeat_rounded, color: colors.primary),
                        ),
                        title: Text(
                          verseTitle(ref),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${c.t('Jadwal', 'Due')}: ${dueDate(
                            (reviews[ref] as Map?)?['due']?.toString() ??
                                practiceDate(DateTime.now()),
                          )}',
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            color: colors.primary, size: 16),
                        onTap: loading ? null : () => openPractice(ref),
                      ),
                    ),
                  ),
              const SizedBox(height: 26),
              _ReviewHeading(
                icon: Icons.calendar_month_rounded,
                title: c.t('Jadwal mendatang', 'Upcoming reviews'),
                count: upcoming.length,
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                Card(
                  key: const Key('murajaah-upcoming-empty'),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.event_available_rounded,
                              color: colors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            memorized == 0
                                ? c.t(
                                    'Jadwal berikutnya akan muncul setelah kamu mulai menghafal.',
                                    'Your next reviews will appear once you start memorizing.',
                                  )
                                : c.t(
                                    'Belum ada jadwal mendatang. Terus jaga hafalanmu.',
                                    'No upcoming reviews yet. Keep your memorization strong.',
                                  ),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < upcoming.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          key: ValueKey('murajaah-upcoming-${upcoming[i].key}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5,
                          ),
                          leading: Icon(Icons.event_rounded,
                              color: colors.primary),
                          title: Text(
                            verseTitle(upcoming[i].key),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            dueDate((upcoming[i].value as Map)['due'] as String),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 26),
              _ReviewHeading(
                icon: Icons.lightbulb_outline_rounded,
                title: c.t('Cara jadwal bekerja', 'How the schedule works'),
              ),
              const SizedBox(height: 12),
              Card(
                key: const Key('murajaah-guide'),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    children: [
                      _GuideRow(
                        number: '01',
                        title: c.t('Perlu diulang', 'Needs practice'),
                        description: c.t(
                          'Ulangi lagi setelah 1 hari',
                          'Review again after 1 day',
                        ),
                      ),
                      const Divider(height: 20),
                      _GuideRow(
                        number: '03',
                        title: c.t('Dengan bantuan', 'With help'),
                        description: c.t(
                          'Ulangi lagi setelah 3 hari',
                          'Review again after 3 days',
                        ),
                      ),
                      const Divider(height: 20),
                      _GuideRow(
                        number: '07',
                        title: c.t('Lancar', 'Fluent'),
                        description: c.t(
                          'Ulangi lagi setelah 7 hari',
                          'Review again after 7 days',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.t(
                  'Jadwal dihitung dari penilaian kelancaranmu sendiri, bukan hasil koreksi AI.',
                  'The schedule is based on your own fluency rating, not an AI assessment.',
                ),
                style: Theme.of(c).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(c).textTheme.headlineMedium?.copyWith(
          color: AppColors.goldLight, fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2F1E9), fontSize: 12, height: 1.3,
        ),
      ),
    ],
  );
}

class _ReviewHeading extends StatelessWidget {
  const _ReviewHeading({
    required this.icon,
    required this.title,
    this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext c) {
    final colors = Theme.of(c).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 22, color: colors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(c).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext c) {
    final colors = Theme.of(c).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: colors.primary, fontWeight: FontWeight.w800, fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(c).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(
                color: colors.onSurfaceVariant, height: 1.4,
              )),
            ],
          ),
        ),
      ],
    );
  }
}
