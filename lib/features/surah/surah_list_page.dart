import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import 'surah_detail_page.dart';
import '../../core/constants/app_colors.dart';

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
                          side: BorderSide(color: Theme.of(c).colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(c).colorScheme.primaryContainer,
                            child: Text('${s.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${s.count} ${c.t('ayat', 'verses')}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 125),
                                child: Text(s.arabic, textDirection: TextDirection.rtl,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 19, color: AppColors.emerald)),
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
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (c, i) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Theme.of(c).colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            leading: CircleAvatar(
              backgroundColor: Theme.of(c).colorScheme.primaryContainer,
              child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text('Juz ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${q.chapters[q.juz[i][0] - 1].name} : ${q.juz[i][1]}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              c,
              MaterialPageRoute<void>(builder: (_) => SurahDetailPage(juz: i + 1)),
            ),
          ),
        ),
      ),
    );
  }
}
