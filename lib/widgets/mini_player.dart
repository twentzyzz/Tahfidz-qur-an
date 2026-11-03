import 'package:flutter/material.dart';

import '../app/session.dart';
import '../l10n/app_strings.dart';
import '../services/player_controller.dart';
import '../features/qari/qari_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final player = Session.of(context).player;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        if (player.current == null && !player.loading && !player.failed) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        final reciter = qaris[player.qari] ?? context.t('Qari', 'Reciter');
        return Material(
          color: scheme.surface,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player.loading) const LinearProgressIndicator(minHeight: 3),
                if (player.failed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      context.t('Audio gagal. Periksa koneksi lalu coba lagi.',
                          'Audio unavailable. Check connection and retry.'),
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: scheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => const QariPage()),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.current == null
                                    ? context.t('Pemutar Murottal', 'Quran audio')
                                    : '${context.t('Ayat', 'Verse')} ${player.current!.ref}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(reciter, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.t('Sebelumnya', 'Previous'),
                        onPressed: player.current == null ? null : () => player.move(-1),
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.t('Putar / jeda', 'Play / pause'),
                        onPressed: player.current == null ? null : player.toggle,
                        icon: Icon(player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                      IconButton(
                        tooltip: context.t('Berikutnya', 'Next'),
                        onPressed: player.current == null ? null : () => player.move(1),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      IconButton(
                        tooltip: context.t('Hentikan', 'Stop'),
                        onPressed: player.stop,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}
