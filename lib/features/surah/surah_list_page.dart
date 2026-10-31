import 'package:flutter/material.dart';

import '../../services/quran_service.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/empty_state.dart';
import 'surah_detail_page.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});
  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final surahs = const QuranCatalog().search(_query);
    return PageLayout(
      title: 'Daftar Surah',
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            labelText: 'Cari nama atau nomor surah',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '7 metadata surah awal. Katalog lengkap 114 surah akan dihubungkan melalui EQuran.id.',
        ),
        const SizedBox(height: 16),
        if (surahs.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'Surah tidak ditemukan',
            message: 'Coba nama lain. Katalog tahap pertama belum lengkap.',
          ),
        for (final surah in surahs)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${surah.number}')),
              title: Text(surah.name),
              subtitle: Text('${surah.verseCount} ayat'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SurahDetailPage(surah: surah),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
