import '../../widgets/weekly_progress.dart';
import '../../services/practice_store.dart';
import 'practice_calendar.dart';
import '../surah/surah_detail_page.dart';

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});
  @override
  Widget build(BuildContext c) {
    final s = Session.of(c), p = Session.of(c).store.map('progress');
    final done = p.values.where((v) => v == 'done').length;
    final history = List<Map<String, dynamic>>.from(
      (s.store.data['history'] as List? ?? []).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final daily =
        (s.store.dailyRecord(DateTime.now())['refs'] as List? ?? []).length;
    return padded([
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: done / 6236,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(c)
                            .colorScheme
                            .primaryContainer,
                      ),
                    ),
                    Text(
                      '${(done / 6236 * 100).toStringAsFixed(1)}%',
                      style: Theme.of(c).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$done / 6236 ${c.t('ayat sudah hafal', 'verses memorized')}',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${c.t('Target harian', 'Daily goal')}: $daily / ${s.store.get('goal', 5)}',
      ),
      DropdownButton<int>(
        value: s.store.get('goal', 5),
        items: [1, 3, 5, 10, 20]
            .map(
              (n) => DropdownMenuItem(
                value: n,
                child: Text('$n ${c.t('ayat per hari', 'verses per day')}'),
              ),
            )
            .toList(),
        onChanged: (v) => perform(c, () => s.store.changeDailyGoal(v!)),
      ),
      Text(
        daily >= s.store.get<int>('goal', 5)
            ? c.t('Target hari ini tercapai', "Today's goal reached")
            : c.t('Target hari ini belum tercapai', "Today's goal not reached"),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          c,
          MaterialPageRoute<void>(builder: (_) => const PracticeCalendar()),
        ),
        icon: const Icon(Icons.calendar_month),
        label: Text(
          c.t('Kalender & hasil latihan', 'Calendar & practice results'),
        ),
      ),
      const SizedBox(height: 24),
      WeeklyProgress(
        counts: weeklyCounts(p, history, DateTime.now()),
        now: DateTime.now(),
      ),
      const SizedBox(height: 24),
      Text(
        c.t('Perjalanan per surah', 'Your chapters'),
        style: Theme.of(c).textTheme.titleLarge,
      ),
      if (p.isEmpty)
        Text(
          c.t(
            'Mulai hafalan untuk melihat progres per surah.',
            'Start memorizing to see chapter progress.',
          ),
        ),
      for (final surah in s.quran.chapters)
        if (p.keys.any((k) => k.startsWith('${surah.number}:')))
          ListTile(
            onTap: () => Navigator.push(
              c,
              MaterialPageRoute<void>(
                builder: (_) =>
                    SurahDetailPage(number: surah.number, memorize: true),
              ),
            ),
            title: Text(surah.name),
            subtitle: LinearProgressIndicator(
              value:
                  p.entries
                      .where(
                        (e) =>
                            e.key.startsWith('${surah.number}:') &&
                            e.value == 'done',
                      )
                      .length /
                  surah.count,
            ),
            trailing: Text(
              '${p.entries.where((e) => e.key.startsWith('${surah.number}:') && e.value == 'done').length}/${surah.count}',
            ),
          ),
      const SizedBox(height: 20),
      Text(
        c.t('Riwayat hafalan', 'Memorization history'),
        style: Theme.of(c).textTheme.titleLarge,
      ),
      if (history.isEmpty)
        Text(c.t('Belum ada progres tersimpan', 'No saved progress yet')),
      for (final h in history.take(100))
        ListTile(
          title: Text(
            '${h['ref']} • ${h['status'] == 'done'
                ? c.t('Sudah hafal', 'Memorized')
                : h['status'] == 'learning'
                ? c.t('Sedang dihafal', 'Learning')
                : c.t('Reset', 'Reset')}',
          ),
          subtitle: Text('${h['time']}'),
        ),
    ]);
  }
}
