import 'package:flutter/material.dart';

import '../../models/surah.dart';
import '../../services/quran_service.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/empty_state.dart';

class TahfidzPage extends StatefulWidget {
  const TahfidzPage({super.key, this.initialSurah});
  final Surah? initialSurah;
  @override
  State<TahfidzPage> createState() => _TahfidzPageState();
}

class _TahfidzPageState extends State<TahfidzPage> {
  Surah? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initialSurah;
  }

  @override
  Widget build(BuildContext context) => PageLayout(
    title: 'Mulai Menghafal',
    children: [
      Text(
        'Siapkan sesi Anda',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'Pilih surah sebagai langkah awal. Sesi hafalan akan tersedia setelah data ayat dan audio diintegrasikan.',
      ),
      const SizedBox(height: 24),
      DropdownButtonFormField<Surah>(
        initialValue: _selected,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Pilih surah'),
        items: QuranCatalog.surahs
            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
            .toList(),
        onChanged: (value) => setState(() => _selected = value),
      ),
      if (_selected != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Pilihan Anda: ${_selected!.name} • ${_selected!.verseCount} ayat',
          ),
        ),
      const EmptyState(
        icon: Icons.repeat_rounded,
        title: 'Mode tahfidz segera hadir',
        message: 'Pemilihan rentang ayat, qari, dan jumlah pengulangan akan hadir di tahap berikutnya.',
      ),
      const FilledButton(
        onPressed: null,
        child: Text('Mulai sesi · belum tersedia'),
      ),
    ],
  );
}
