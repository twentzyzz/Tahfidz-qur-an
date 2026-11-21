import '../../widgets/weekly_progress.dart';
import '../../services/practice_store.dart';
import 'practice_calendar.dart';
import 'detailed_stats_page.dart';
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
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064735), Color(0xFF087F5B)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC5A064), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064735).withValues(alpha: .16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                        strokeWidth: 9,
                        color: const Color(0xFFF0D49A),
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Text(
                      '${(done / 6236 * 100).toStringAsFixed(1)}%',
                      style: Theme.of(c).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$done / 6236 ${c.t('ayat sudah hafal', 'verses memorized')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('open-detailed-stats'),
          onPressed: () => Navigator.push(
            c,
            MaterialPageRoute<void>(
              builder: (_) => const DetailedStatsPage(),
            ),
          ),
          icon: const Icon(Icons.bar_chart_rounded),
          label: Text(c.t('Statistik Hafalan Detail', 'Detailed memorization statistics')),
        ),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes_rounded,
                      color: Theme.of(c).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.t('Target harian', 'Daily goal'),
                      style: Theme.of(c).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$daily / ${s.store.get('goal', 5)}',
                    style: Theme.of(c).textTheme.titleMedium?.copyWith(
                      color: Theme.of(c).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (daily / s.store.get<int>('goal', 5)).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey('daily-goal-${s.store.get<int>('goal', 5)}'),
                initialValue: s.store.get<int>('goal', 5),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: c.t('Ayat per hari', 'Verses per day'),
                  prefixIcon: const Icon(Icons.flag_outlined),
                ),
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
              const SizedBox(height: 12),
              Text(
                daily >= s.store.get<int>('goal', 5)
                    ? c.t('Target hari ini tercapai', "Today's goal reached")
                    : c.t('Target hari ini belum tercapai', "Today's goal not reached"),
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(c).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WeeklyProgress(
                counts: weeklyCounts(p, history, DateTime.now()),
                now: DateTime.now(),
              ),
              if (weeklyCounts(p, history, DateTime.now())
                  .every((count) => count == 0)) ...[
                const SizedBox(height: 16),
                Text(
                  c.t(
                    'Belum ada ayat yang ditandai hafal pekan ini. Mulai dari satu ayat.',
                    'No verses marked memorized this week. Begin with one verse.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(c).textTheme.bodySmall?.copyWith(
                    color: Theme.of(c).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Icon(Icons.auto_stories_rounded,
              color: Theme.of(c).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c.t('Perjalanan per surah', 'Your chapters'),
              style: Theme.of(c).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      if (p.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    color: Theme.of(c).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.t(
                      'Mulai hafalan untuk melihat progres per surah.',
                      'Start memorizing to see chapter progress.',
                    ),
                  ),
                ),
              ],
            ),
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
      Row(
        children: [
          Icon(Icons.history_rounded,
              color: Theme.of(c).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c.t('Riwayat hafalan', 'Memorization history'),
              style: Theme.of(c).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      if (history.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(c.t('Belum ada progres tersimpan', 'No saved progress yet')),
          ),
        ),
      for (final h in history.take(100))
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(c).colorScheme.primaryContainer,
              child: Icon(
                h['status'] == 'done'
                    ? Icons.check_rounded
                    : h['status'] == 'learning'
                        ? Icons.bookmark_outline_rounded
                        : Icons.restart_alt_rounded,
                color: Theme.of(c).colorScheme.primary,
              ),
            ),
            title: Text(
              '${h['ref']} • ${h['status'] == 'done'
                  ? c.t('Sudah hafal', 'Memorized')
                  : h['status'] == 'learning'
                      ? c.t('Sedang dihafal', 'Learning')
                      : c.t('Reset', 'Reset')}',
            ),
            subtitle: Text('${h['time']}'),
          ),
        ),
    ]);
  }
}
