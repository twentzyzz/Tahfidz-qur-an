import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/memorization_stats.dart';
import '../../services/quiz_history_store.dart';
import '../tahfidz/quiz_history_page.dart';

class DetailedStatsPage extends StatelessWidget {
  const DetailedStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MemorizationStats(Session.of(context).store);
    final counts = stats.lastSevenDays();
    final peak = math.max(1, counts.reduce(math.max));
    final quizSummary = QuizHistorySummary(Session.of(context).store.quizAttempts);
    final ratings = stats.practiceRatings;
    final totalRatings = ratings.values.fold<int>(0, (a, b) => a + b);
    final needsPractice = stats.needsPractice;
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Statistik Hafalan', 'Memorization statistics'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  context.t(
                    'Ringkasan berdasarkan catatan hafalan di perangkat ini.',
                    'Summary based on memorization records on this device.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric(label: context.t('Sudah hafal', 'Memorized'),
                        value: '${stats.memorized}', icon: Icons.check_circle_outline),
                    _Metric(label: context.t('Sedang dihafal', 'Learning'),
                        value: '${stats.learning}', icon: Icons.menu_book_outlined),
                    _Metric(label: context.t('Perlu murajaah', 'Due for review'),
                        value: '${stats.due}', icon: Icons.event_repeat),
                    _Metric(label: context.t('Streak aktivitas', 'Activity streak'),
                        value: '${stats.streak} ${context.t('hari', 'days')}',
                        icon: Icons.local_fire_department_outlined),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('Aktivitas 7 hari terakhir', 'Activity in the last 7 days'),
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          context.t(
                            '${stats.activeDaysLastSeven} hari aktif • ayat yang ditandai hafal per hari',
                            '${stats.activeDaysLastSeven} active days • verses marked memorized each day',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < counts.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('${counts[i]}',
                                            style: Theme.of(context).textTheme.labelSmall),
                                        const SizedBox(height: 6),
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: FractionallySizedBox(
                                              heightFactor: counts[i] == 0
                                                  ? .025
                                                  : counts[i] / peak,
                                              child: Container(
                                                key: ValueKey('stats-bar-$i'),
                                                decoration: BoxDecoration(
                                                  color: colors.primary,
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(7),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${DateTime(today.year, today.month, today.day - 6 + i).day}',
                                          style: Theme.of(context).textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.t(
                            'Angka ini mencatat aktivitas saat ditandai hafal, termasuk ayat yang kemudian direset.',
                            'Counts record when verses were marked memorized, including later resets.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('Riwayat Nilai Kuis', 'Quiz score history'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quizSummary.count == 0
                              ? context.t('Belum ada kuis yang selesai.', 'No completed quizzes yet.')
                              : context.t(
                                  '${quizSummary.count} kuis • Terbaik ${quizSummary.bestPercent}% • Rata-rata ${quizSummary.averagePercent}%',
                                  '${quizSummary.count} quizzes • Best ${quizSummary.bestPercent}% • Average ${quizSummary.averagePercent}%',
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('open-quiz-history-from-stats'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const QuizHistoryPage(),
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: Text(context.t('Lihat Riwayat Nilai', 'View quiz history')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('Penilaian latihan manual', 'Manual practice ratings'),
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          context.t(
                            '$totalRatings penilaian tersimpan, bukan skor akurasi bacaan.',
                            '$totalRatings saved ratings, not a recitation accuracy score.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RatingRow(label: context.t('Ulangi', 'Again'),
                            count: ratings['again']!, total: totalRatings),
                        _RatingRow(label: context.t('Perlu bantuan', 'Need help'),
                            count: ratings['help']!, total: totalRatings),
                        _RatingRow(label: context.t('Lancar', 'Fluent'),
                            count: ratings['fluent']!, total: totalRatings),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('Ayat yang perlu latihan lagi', 'Verses to practice again'),
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          context.t(
                            'Diurutkan dari penilaian manual "Ulangi" terbanyak.',
                            'Sorted by the most manual "Again" ratings.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (needsPractice.isEmpty)
                          Text(context.t('Belum ada catatan latihan.', 'No practice ratings yet.')),
                        for (final item in needsPractice)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.key),
                            trailing: Text('${item.value}×'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.count, required this.total});
  final String label;
  final int count, total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(children: [
          Expanded(child: Text(label)),
          Text('$count'),
        ]),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: total == 0 ? 0 : count / total,
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    ),
  );
}
