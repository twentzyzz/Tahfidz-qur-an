import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/practice_store.dart';
import '../../widgets/common.dart';
import '../tahfidz/practice_page.dart';
import '../offline_recitation/offline_recitation_page.dart';
import '../../services/offline_recitation/domain.dart';

class PracticeCalendar extends StatefulWidget {
  const PracticeCalendar({super.key});
  @override
  State<PracticeCalendar> createState() => _PracticeCalendarState();
}

class _PracticeCalendarState extends State<PracticeCalendar> {
  DateTime selected = DateTime.now();
  @override
  Widget build(BuildContext c) {
    final store = Session.of(c).store;
    final day = store.dailyRecord(selected);
    final refs = List<String>.from(day['refs'] as List? ?? []);
    final goal = store.dailyTarget(selected);
    final sessions = (store.data['practiceSessions'] as List? ?? [])
        .where((s) => (s['time'] as String).startsWith(practiceDate(selected)))
        .toList();
    final offlineSessions =
        (store.data['offlineRecitationSessions'] as List? ?? [])
            .where(
              (s) => (s['time'] as String).startsWith(practiceDate(selected)),
            )
            .toList();
    final dates = store.dailyRecords.keys.map(DateTime.parse).toList()..sort();
    final first = dates.isEmpty ? DateTime.now() : dates.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.t('Kalender hafalan', 'Memorization calendar')),
      ),
      body: padded([
        CalendarDatePicker(
          initialDate: selected,
          firstDate: DateTime(first.year < 2020 ? first.year : 2020),
          lastDate: DateTime.now(),
          onDateChanged: (date) => setState(() => selected = date),
        ),
        Text(
          MaterialLocalizations.of(c).formatFullDate(selected),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        Text(
          '${refs.length} ${c.t('ayat ditandai hafal pada tanggal ini', 'verses marked memorized on this date')}',
        ),
        Text(
          goal == null
              ? c.t(
                  'Target tanggal ini tidak tercatat.',
                  'No target was recorded for this date.',
                )
              : '${c.t('Target', 'Goal')}: ${refs.length} / $goal — ${refs.length >= goal ? c.t('Tercapai', 'Reached') : c.t('Belum tercapai', 'Not reached')}',
        ),
        Text(
          c.t(
            'Catatan aktivitas tetap tersimpan meskipun status ayat kemudian direset. Target lama yang tidak tercatat tidak diperkirakan.',
            'Activity remains recorded even if a verse is later reset. Missing historical targets are not estimated.',
          ),
        ),
        if (refs.isNotEmpty) Text(refs.join(', ')),
        const SizedBox(height: 24),
        Text(
          c.t('Hasil latihan manual', 'Manual practice results'),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        if (sessions.isEmpty && offlineSessions.isEmpty)
          Text(
            c.t(
              'Belum ada hasil latihan pada tanggal ini.',
              'No practice results on this date.',
            ),
          ),
        for (final raw in offlineSessions)
          ListTile(
            title: Text('AI Offline • ${(raw['refs'] as List).join(', ')}'),
            subtitle: Text(
              recitationStatusLabel(
                c,
                RecitationStatus.values.firstWhere(
                  (status) => status.name == raw['status'],
                  orElse: () => RecitationStatus.unassessed,
                ),
              ),
            ),
            trailing: IconButton(
              tooltip: c.t('Hapus ringkasan', 'Delete summary'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => perform(
                c,
                () => store.update((next) {
                  next['offlineRecitationSessions'] =
                      (next['offlineRecitationSessions'] as List)
                          .where((session) => session['id'] != raw['id'])
                          .toList();
                }),
              ),
            ),
          ),
        for (final raw in sessions) ...[
          const Divider(),
          Text(
            '${raw['time']} • ${raw['mode'] == 'review'
                ? 'Murajaah'
                : raw['mode'] == 'continue'
                ? c.t('Sambung ayat', 'Continue verse')
                : c.t('Sembunyikan teks', 'Hide text')}',
          ),
          for (final entry in Map<String, dynamic>.from(
            raw['ratings'] as Map,
          ).entries)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(ratingLabel(c, entry.value as String)),
            ),
        ],
      ]),
    );
  }
}
