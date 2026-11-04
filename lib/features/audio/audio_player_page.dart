import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/player_controller.dart';
import '../../core/theme/app_typography.dart';
import '../qari/qari_page.dart';

class AudioPlayerPage extends StatelessWidget {
  const AudioPlayerPage({super.key});
  @override
  Widget build(BuildContext c) {
    final s = Session.of(c), p = Session.of(c).player;
    final cs = Theme.of(c).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Pemutar Murottal', 'Quran audio'))),
      body: ListenableBuilder(
        listenable: p,
        builder: (c, _) {
          final verse = p.current;
          if (verse == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.headphones_rounded, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      c.t(
                        'Pilih ayat untuk mulai mendengarkan.',
                        'Choose a verse to start listening.',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(c.t('Kembali', 'Back')),
                    ),
                  ],
                ),
              ),
            );
          }
          final chapter = s.quran.chapters[verse.surah - 1];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: QariAvatar(name: qaris[p.qari] ?? p.qari, size: 112),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    qaris[p.qari] ?? p.qari,
                    textAlign: TextAlign.center,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      c,
                      MaterialPageRoute<void>(builder: (_) => const QariPage()),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(c.t('Ganti qari', 'Change reciter')),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    chapter.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(c).textTheme.headlineMedium,
                  ),
                  Text(
                    '${c.t('Ayat', 'Verse')} ${verse.number} / ${chapter.count}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  SelectableText(
                    verse.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: AppTypography.arabic.copyWith(
                      fontSize: s.store.get<num>('arabicSize', 32).toDouble(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (p.loading) const LinearProgressIndicator(),
                  if (p.failed)
                    Column(
                      children: [
                        Text(
                          c.t(
                            'Audio gagal dimuat. Periksa koneksi.',
                            'Unable to load audio. Check your connection.',
                          ),
                          style: TextStyle(color: cs.error),
                        ),
                        TextButton(
                          onPressed: () => p.play(
                            List.of(p.verses),
                            p.qari,
                            p.repeats,
                            initialIndex: p.index,
                          ),
                          child: Text(c.t('Coba lagi', 'Retry')),
                        ),
                      ],
                    ),
                  AudioTimeline(player: p),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 32,
                        tooltip: c.t('Sebelumnya', 'Previous'),
                        onPressed: p.loading || p.index == 0
                            ? null
                            : () => p.move(-1),
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        iconSize: 40,
                        padding: const EdgeInsets.all(16),
                        tooltip: c.t('Putar / jeda', 'Play / pause'),
                        onPressed: p.loading || p.failed ? null : p.toggle,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            p.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(p.playing),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 32,
                        tooltip: c.t('Berikutnya', 'Next'),
                        onPressed:
                            p.loading ||
                                p.index >= p.verses.length * p.repeats - 1
                            ? null
                            : () => p.move(1),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    key: ValueKey(p.repeats),
                    initialValue: p.repeats,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.repeat_rounded),
                      labelText: c.t(
                        'Ulangi rentang ayat',
                        'Repeat verse range',
                      ),
                    ),
                    items: [1, 3, 5, 10]
                        .map(
                          (n) =>
                              DropdownMenuItem(value: n, child: Text('$n ×')),
                        )
                        .toList(),
                    onChanged: p.loading ? null : (n) => p.changeRepeats(n!),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: p.stop,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(c.t('Hentikan audio', 'Stop audio')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AudioTimeline extends StatelessWidget {
  const AudioTimeline({super.key, required this.player, this.compact = false});
  final PlayerController player;
  final bool compact;
  String time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext c) => StreamBuilder<Duration?>(
    stream: player.durationStream,
    initialData: player.duration,
    builder: (c, duration) => StreamBuilder<Duration>(
      stream: player.positionStream,
      initialData: player.position,
      builder: (c, position) {
        final total = duration.data?.inMilliseconds ?? 0;
        final elapsed = (position.data?.inMilliseconds ?? 0).clamp(
          0,
          total > 0 ? total : 0,
        );
        if (compact) {
          return LinearProgressIndicator(
            value: total > 0 ? elapsed / total : 0,
            minHeight: 2,
          );
        }
        return Column(
          children: [
            Slider(
              value: elapsed.toDouble(),
              max: total > 0 ? total.toDouble() : 1,
              semanticFormatterCallback: (v) =>
                  time(Duration(milliseconds: v.round())),
              onChanged: total > 0 && !player.loading
                  ? (v) => player.seek(Duration(milliseconds: v.round()))
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time(Duration(milliseconds: elapsed))),
                Text(time(Duration(milliseconds: total))),
              ],
            ),
          ],
        );
      },
    ),
  );
}
