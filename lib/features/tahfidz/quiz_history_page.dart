import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/quiz_history_store.dart';

class QuizHistoryPage extends StatelessWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Session.of(context).store.quizAttempts;
    final summary = QuizHistorySummary(history);
    final colors = Theme.of(context).colorScheme;
    final recent = history.take(7).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('Riwayat Nilai Kuis', 'Quiz score history'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  context.t(
                    'Hasil Kuis Sambung Ayat yang sudah selesai, tersimpan hanya di perangkat ini.',
                    'Completed Next Verse Quiz results, stored only on this device.',
                  ),
                ),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 42, color: colors.primary),
                          const SizedBox(height: 12),
                          Text(
                            context.t(
                              'Belum ada hasil kuis. Selesaikan satu kuis untuk melihat nilainya di sini.',
                              'No quiz results yet. Finish a quiz to see your scores here.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SummaryTile(
                        label: context.t('Total percobaan', 'Attempts'),
                        value: '${summary.count}',
                        icon: Icons.format_list_numbered_rounded,
                      ),
                      _SummaryTile(
                        label: context.t('Nilai tertinggi', 'Best score'),
                        value: '${summary.bestPercent}%',
                        icon: Icons.emoji_events_outlined,
                      ),
                      _SummaryTile(
                        label: context.t('Rata-rata', 'Average'),
                        value: '${summary.averagePercent}%',
                        icon: Icons.analytics_outlined,
                      ),
                      _SummaryTile(
                        label: context.t('Terakhir', 'Latest'),
                        value: '${summary.latestPercent}%',
                        icon: Icons.update_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('Perkembangan 7 kuis terakhir', 'Last 7 quiz scores'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.t('Persentase jawaban benar per kuis, dari lama ke baru.',
                                'Correct answers per quiz, oldest to newest.'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 155,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < recent.length; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Column(
                                        children: [
                                          Text('${recent[i].percent}%',
                                              style: Theme.of(context).textTheme.labelSmall),
                                          const SizedBox(height: 7),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: FractionallySizedBox(
                                                heightFactor: recent[i].percent == 0
                                                    ? .03
                                                    : recent[i].percent / 100,
                                                child: Container(
                                                  key: ValueKey('quiz-history-bar-$i'),
                                                  decoration: BoxDecoration(
                                                    color: colors.primary,
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text('${i + 1}',
                                              style: Theme.of(context).textTheme.labelSmall),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(context.t('Semua percobaan', 'All attempts'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final entry in history)
                    Card(
                      child: ListTile(
                        key: ValueKey('quiz-history-${entry.id}'),
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.quiz_outlined, color: colors.onPrimaryContainer),
                        ),
                        title: Text(
                          '${_surahName(context, entry.surah)} • ${entry.correct}/${entry.total}',
                        ),
                        subtitle: Text(_formattedDate(entry.time.toLocal())),
                        trailing: Text('${entry.percent}%',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  context.t(
                    'Nilai kuis mengukur pilihan jawaban dalam latihan, bukan ketepatan tajwid atau status hafalan.',
                    'Quiz scores measure selected answers, not tajweed accuracy or memorization status.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _surahName(BuildContext context, int surah) {
    final chapters = Session.of(context).quran.chapters;
    return surah <= chapters.length
        ? chapters[surah - 1].name
        : '${context.t('Surah', 'Surah')} $surah';
  }

  String _formattedDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label, required this.value, required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
