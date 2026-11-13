import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/practice_store.dart';
import '../../services/quran_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/mini_player.dart';

String ratingLabel(BuildContext c, String rating) => switch (rating) {
  'again' => c.t('Perlu diulang', 'Needs practice'),
  'help' => c.t('Dengan bantuan', 'With help'),
  _ => c.t('Lancar', 'Fluent'),
};

class PracticePage extends StatefulWidget {
  const PracticePage({super.key, required this.verses, this.review = false});
  final List<Verse> verses;
  final bool review;
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late String mode = widget.review ? 'review' : 'hidden';
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final ratings = <String, String>{};
  int index = 0;
  bool started = false,
      revealed = false,
      saving = false,
      saved = false,
      advancing = false;

  Future<bool> confirmExit() async {
    if (!started || saved) return true;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(c.t('Keluar dari latihan?', 'Leave practice?')),
            content: Text(
              c.t(
                'Hasil yang belum disimpan akan dibuang.',
                'Unsaved results will be discarded.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(c.t('Lanjut latihan', 'Keep practicing')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(c.t('Keluar', 'Leave')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext c) {
    final session = Session.of(c);
    final complete = index == widget.verses.length;
    return PopScope(
      canPop: !started || saved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || saving) return;
        if (await confirmExit() && c.mounted) {
          setState(() => started = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.mounted) Navigator.pop(c);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.review
                ? 'Murajaah'
                : c.t('Ujian hafalan', 'Memorization exam'),
          ),
        ),
        bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
        body: padded([
          Text(
            c.t(
              'Latihan manual • tanpa penilaian AI',
              'Manual practice • no AI assessment',
            ),
          ),
          const SizedBox(height: 16),
          if (!started) ...[
            Text(
              '${widget.verses.length} ${c.t('ayat dalam latihan', 'verses in this practice')}',
            ),
            if (!widget.review)
              DropdownButtonFormField<String>(
                initialValue: mode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: c.t('Mode ujian', 'Exam mode'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'hidden',
                    child: Text(c.t('Sembunyikan teks', 'Hide text')),
                  ),
                  DropdownMenuItem(
                    value: 'continue',
                    child: Text(c.t('Sambung ayat', 'Continue verse')),
                  ),
                ],
                onChanged: (v) => setState(() => mode = v!),
              ),
            const SizedBox(height: 16),
            Text(
              c.t(
                'Baca dari ingatan, buka jawaban, lalu nilai kelancaran sendiri. Audio contoh memerlukan internet.',
                'Recite from memory, reveal the answer, then assess yourself. Example audio needs internet.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.verses.isEmpty
                  ? null
                  : () => perform(c, () async {
                      await session.player.stop();
                      if (mounted) setState(() => started = true);
                    }),
              child: Text(c.t('Mulai ujian', 'Start practice')),
            ),
          ] else if (complete) ...[
            Text(
              c.t('Ringkasan latihan', 'Practice summary'),
              style: Theme.of(c).textTheme.headlineSmall,
            ),
            Text(
              c.t(
                'Hasil ini berdasarkan penilaian Anda. Status hafalan tidak diubah otomatis.',
                'These are your own assessments. Memorization status is not changed automatically.',
              ),
            ),
            for (final rating in reviewIntervals.keys)
              ListTile(
                title: Text(ratingLabel(c, rating)),
                trailing: Text(
                  '${ratings.values.where((v) => v == rating).length}',
                ),
              ),
            for (final entry in ratings.entries)
              ListTile(
                title: Text(entry.key),
                subtitle: Text(ratingLabel(c, entry.value)),
              ),
            Text(
              c.t(
                'Simpan untuk mencatat hasil di perangkat dan memperbarui jadwal ayat yang sudah hafal. Tidak ada rekaman suara.',
                'Save to keep results on this device and update reviews for memorized verses. No audio is recorded.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saved || saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      await perform(c, () async {
                        await session.store.savePractice(
                          id: id,
                          mode: mode,
                          ratings: ratings,
                        );
                        if (mounted) setState(() => saved = true);
                      });
                      if (mounted) setState(() => saving = false);
                    },
              child: Text(
                saved
                    ? c.t('Hasil tersimpan', 'Results saved')
                    : saving
                    ? c.t('Menyimpan…', 'Saving…')
                    : c.t('Simpan hasil', 'Save results'),
              ),
            ),
            if (saved)
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(c.t('Selesai', 'Done')),
              ),
          ] else ...[
            Text(
              '${index + 1} / ${widget.verses.length}',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            Text(
              '${session.quran.chapters[widget.verses[index].surah - 1].name} • ${widget.verses[index].number}',
            ),
            const SizedBox(height: 16),
            if (mode == 'continue' && index > 0) ...[
              Text(
                c.t(
                  'Lanjutkan setelah ayat ini:',
                  'Continue after this verse:',
                ),
              ),
              SelectableText(
                widget.verses[index - 1].arabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabic.copyWith(fontSize: 28, height: 2),
              ),
            ],
            if (!revealed) ...[
              Text(
                c.t(
                  'Bacakan ayat dari ingatan.',
                  'Recite the verse from memory.',
                ),
              ),
              FilledButton(
                onPressed: () => setState(() => revealed = true),
                child: Text(c.t('Tampilkan jawaban', 'Reveal answer')),
              ),
            ] else ...[
              SelectableText(
                widget.verses[index].arabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabic.copyWith(
                  fontSize: session.store.get<num>('arabicSize', 32).toDouble(),
                  height: 2,
                ),
              ),
              Text(widget.verses[index].translation),
              OutlinedButton.icon(
                onPressed: () => session.player.play(
                  [widget.verses[index]],
                  session.store.get('qari', '05'),
                  1,
                ),
                icon: const Icon(Icons.volume_up),
                label: Text(c.t('Dengarkan contoh', 'Listen to example')),
              ),
              Text(c.t('Bagaimana kelancaran Anda?', 'How fluent were you?')),
              for (final rating in reviewIntervals.keys)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    onPressed: advancing
                        ? null
                        : () async {
                            setState(() => advancing = true);
                            final ref = widget.verses[index].ref;
                            await perform(c, () async {
                              await session.player.stop();
                              if (!mounted) return;
                              setState(() {
                                ratings[ref] = rating;
                                index++;
                                revealed = false;
                              });
                            });
                            if (mounted) setState(() => advancing = false);
                          },
                    child: Text(ratingLabel(c, rating)),
                  ),
                ),
            ],
          ],
        ]),
      ),
    );
  }
}
