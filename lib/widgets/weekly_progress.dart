import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Distinct verses marked memorized on each local calendar day, still memorized.
List<int> weeklyCounts(
  Map<String, dynamic> progress,
  List<Map<String, dynamic>> history,
  DateTime now,
) => List.generate(7, (i) {
  final day = DateTime(
    now.year,
    now.month,
    now.day - 6 + i,
  ).toIso8601String().substring(0, 10);
  return history
      .where(
        (h) =>
            h['status'] == 'done' &&
            progress[h['ref']] == 'done' &&
            h['time'] is String &&
            (h['time'] as String).startsWith(day),
      )
      .map((h) => h['ref'])
      .toSet()
      .length;
});

class WeeklyProgress extends StatelessWidget {
  const WeeklyProgress({super.key, required this.counts, required this.now});
  final List<int> counts;
  final DateTime now;
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    final max = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.t('Tujuh hari terakhir', 'Last seven days'),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          c.t(
            'Ayat unik yang ditandai hafal dan masih tersimpan sebagai hafal.',
            'Distinct verses marked memorized and still saved as memorized.',
          ),
          style: Theme.of(c).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final day = DateTime(now.year, now.month, now.day - 6 + i);
            return Expanded(
              child: Semantics(
                label:
                    '${MaterialLocalizations.of(c).formatFullDate(day)}: ${counts[i]} ${c.t('ayat', 'verses')}',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Text(
                        '${counts[i]}',
                        style: Theme.of(c).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 72,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 20,
                            height: counts[i] == 0 ? 3 : 72 * counts[i] / max,
                            decoration: BoxDecoration(
                              color: i == 6 ? cs.primary : cs.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${day.day}/${day.month}',
                        style: Theme.of(c).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
