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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final daily = history
        .where(
          (h) =>
              h['status'] == 'done' &&
              p[h['ref']] == 'done' &&
              (h['time'] as String).startsWith(today),
        )
        .map((h) => h['ref'])
        .toSet()
        .length;
    return padded([
      Text(
        '${(done / 6236 * 100).toStringAsFixed(1)}%',
        style: Theme.of(c).textTheme.displaySmall,
      ),
      LinearProgressIndicator(value: done / 6236),
      Text('$done / 6236 ${c.t('ayat sudah hafal', 'verses memorized')}'),
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
        onChanged: (v) => perform(c, () => s.store.set('goal', v)),
      ),
      for (final surah in s.quran.chapters)
        if (p.keys.any((k) => k.startsWith('${surah.number}:')))
          ListTile(
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
