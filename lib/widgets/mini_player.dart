import 'package:flutter/material.dart';

import '../app/session.dart';
import '../l10n/app_strings.dart';
import '../services/player_controller.dart';
import '../features/qari/qari_avatar.dart';
import '../features/audio/audio_player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext c) {
    final s = Session.of(c), player = Session.of(c).player;
    return ListenableBuilder(
      listenable: player,
      builder: (c, _) {
        if (player.current == null && !player.loading && !player.failed) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(c).colorScheme;
        final reciter = qaris[player.qari] ?? c.t('Qari', 'Reciter');
        final verse = player.current;
        return Material(
          color: cs.surface,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player.loading)
                  const LinearProgressIndicator(minHeight: 2)
                else if (verse != null)
                  AudioTimeline(player: player, compact: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.push(
                            c,
                            MaterialPageRoute<void>(
                              builder: (_) => const AudioPlayerPage(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                QariAvatar(name: reciter, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        verse == null
                                            ? c.t(
                                                'Pemutar Murottal',
                                                'Quran audio',
                                              )
                                            : '${s.quran.chapters[verse.surah - 1].name} · ${verse.number}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(c).textTheme.titleSmall,
                                      ),
                                      Text(
                                        player.failed
                                            ? c.t(
                                                'Audio gagal · Ketuk untuk mencoba lagi',
                                                'Audio failed · Tap to retry',
                                              )
                                            : reciter,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: player.failed
                                              ? cs.error
                                              : cs.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: c.t('Putar / jeda', 'Play / pause'),
                        onPressed:
                            verse == null || player.loading || player.failed
                            ? null
                            : player.toggle,
                        icon: Icon(
                          player.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: c.t('Hentikan', 'Stop'),
                        onPressed: player.stop,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        );
      },
    );
  }
}
