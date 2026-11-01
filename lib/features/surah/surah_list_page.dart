import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import 'surah_detail_page.dart';

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
                    return ListTile(
                      leading: CircleAvatar(child: Text('${s.number}')),
                      title: Text(s.name),
                      subtitle: Text('${s.count} ${c.t('ayat', 'verses')}'),
                      trailing: Text(
                        s.arabic,
                        textDirection: TextDirection.rtl,
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
      itemBuilder: (c, i) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text('Juz ${i + 1}'),
        subtitle: Text('${q.chapters[q.juz[i][0] - 1].name} : ${q.juz[i][1]}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          c,
          MaterialPageRoute<void>(builder: (_) => SurahDetailPage(juz: i + 1)),
        ),
      ),
    );
  }
}
