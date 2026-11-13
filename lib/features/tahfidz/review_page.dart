import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/practice_store.dart';
import '../../widgets/common.dart';
import 'practice_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool loading = false;
  @override
  Widget build(BuildContext c) {
    final session = Session.of(c);
    final due = session.store.dueReviews(DateTime.now());
    final memorized = session.store
        .map('progress')
        .values
        .where((v) => v == 'done')
        .length;
    final reviews = session.store.map('reviews');
    return Scaffold(
      appBar: AppBar(title: const Text('Murajaah')),
      body: padded([
        Text(
          c.t(
            'Jadwal berdasarkan penilaian Anda: perlu diulang → 1 hari, dengan bantuan → 3 hari, lancar → 7 hari.',
            'Your assessment sets the next review: needs practice → 1 day, with help → 3 days, fluent → 7 days.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${due.length} ${c.t('ayat perlu diulang', 'verses due')}',
          style: Theme.of(c).textTheme.titleLarge,
        ),
        if (due.isEmpty)
          Text(
            memorized == 0
                ? c.t(
                    'Tandai ayat “Sudah hafal” untuk mulai membuat jadwal.',
                    'Mark a verse as memorized to start scheduling reviews.',
                  )
                : c.t(
                    'Semua latihan terjadwal sudah selesai untuk hari ini.',
                    'No scheduled reviews are due today.',
                  ),
          ),
        if (loading) const LinearProgressIndicator(),
        for (final ref in due)
          ListTile(
            title: Text(
              '${session.quran.chapters[int.parse(ref.split(':')[0]) - 1].name} • ${ref.split(':')[1]}',
            ),
            subtitle: Text(
              '${c.t('Jadwal', 'Due')}: ${(reviews[ref] as Map?)?['due'] ?? practiceDate(DateTime.now())}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    await perform(c, () async {
                      final parts = ref.split(':').map(int.parse).toList();
                      final verses = await session.quran.surah(parts[0]);
                      if (!c.mounted) return;
                      await Navigator.push(
                        c,
                        MaterialPageRoute<void>(
                          builder: (_) => PracticePage(
                            verses: [verses[parts[1] - 1]],
                            review: true,
                          ),
                        ),
                      );
                    });
                    if (mounted) setState(() => loading = false);
                  },
          ),
        const SizedBox(height: 16),
        Text(
          c.t('Jadwal mendatang', 'Upcoming reviews'),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        for (final entry in reviews.entries)
          if (session.store.map('progress')[entry.key] == 'done' &&
              !due.contains(entry.key))
            ListTile(
              title: Text(entry.key),
              subtitle: Text('${(entry.value as Map)['due']}'),
            ),
      ]),
    );
  }
}
