import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import 'surah_detail_page.dart';
import '../../core/theme/app_typography.dart';
import '../../services/quran_repository.dart';
import 'reading_catalog.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key, this.memorize = false});
  final bool memorize;
  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  String query = '';
  @override
  Widget build(BuildContext c) {
    if (!widget.memorize) return const ReadingCatalog();
    final session = Session.of(c);
    final chapters = session.quran.chapters
        .where(
          (s) =>
              s.name.toLowerCase().contains(query.trim().toLowerCase()) ||
              s.arabic.contains(query) ||
              '${s.number}' == query.trim(),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: c.t(
                'Cari nama atau nomor surah',
                'Search surah name or number',
              ),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (s) => setState(() => query = s),
          ),
        ),
        Expanded(
          child: chapters.isEmpty
              ? Center(
                  child: Text(c.t('Surah tidak ditemukan', 'No surah found')),
                )
              : ListView.builder(
                  itemCount: chapters.length,
                  itemBuilder: (c, i) {
                    final s = chapters[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(c).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(c)
                                .colorScheme
                                .primaryContainer,
                            child: Text(
                              '${s.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('${s.count} ${c.t('ayat', 'verses')}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 125,
                                ),
                                child: Text(
                                  s.arabic,
                                  textDirection: TextDirection.rtl,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.arabic.copyWith(
                                    fontSize: 19,
                                    color: Theme.of(c).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            c,
                            MaterialPageRoute<void>(
                              builder: (_) => SurahDetailPage(
                                number: s.number,
                                memorize: widget.memorize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class JuzPage extends StatelessWidget {
  const JuzPage({super.key});
  @override
  Widget build(BuildContext c) {
    final q = Session.of(c).quran;
    return CatalogFrame(
      child: ListView.builder(
        key: const PageStorageKey('juz-catalog'),
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: q.juz.length + 1,
        itemBuilder: (c, item) {
          if (item == 0) {
            return CatalogHeading(
              title: c.t('Baca per juz', 'Read by juz'),
              description: c.t(
                '${q.juz.length} bagian, dari Al-Fatihah hingga An-Nas.',
                '${q.juz.length} parts, from Al-Fatihah to An-Nas.',
              ),
            );
          }
          final i = item - 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Theme.of(c).colorScheme.surface,
              elevation: 1,
              shadowColor: const Color(0xFFBFA878).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(c).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  key: ValueKey('juz-${i + 1}'),
                  contentPadding: const EdgeInsets.all(12),
                  leading: CatalogNumber(i + 1),
                  title: Text('Juz ${i + 1}', style: Theme.of(c).textTheme.titleMedium),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${c.t('Mulai', 'From')} ${q.chapters[q.juz[i][0] - 1].name} : ${q.juz[i][1]}\n'
                      '${c.t('Hingga', 'To')} ${juzEnd(q, i)}',
                      style: TextStyle(
                        height: 1.55,
                        color: Theme.of(c).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(c).colorScheme.primary,
                  ),
                  onTap: () => Navigator.push(
                    c,
                    MaterialPageRoute<void>(
                      builder: (_) => SurahDetailPage(juz: i + 1),
                    ),
                  ),
                ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String juzEnd(QuranRepository q, int index) {
  if (index == 29) return '${q.chapters.last.name} : ${q.chapters.last.count}';
  final next = q.juz[index + 1];
  final chapter = q.chapters[next[0] - (next[1] == 1 ? 2 : 1)];
  return '${chapter.name} : ${next[1] == 1 ? chapter.count : next[1] - 1}';
}
