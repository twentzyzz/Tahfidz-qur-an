import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../surah/surah_list_page.dart';

class TahfidzPage extends StatelessWidget {
  const TahfidzPage({super.key});
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          c.t(
            'Pilih surah, tentukan rentang ayat, lalu ulangi audio sambil menyembunyikan teks.',
            'Choose a surah, set a verse range, then repeat audio while hiding the text.',
          ),
        ),
      ),
      const Expanded(child: SurahListPage(memorize: true)),
    ],
  );
}
