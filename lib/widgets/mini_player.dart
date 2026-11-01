import 'package:flutter/material.dart';

import '../app/session.dart';
import '../l10n/app_strings.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext c) {
    final p = Session.of(c).player;
    return ListenableBuilder(
      listenable: p,
      builder: (c, _) {
        if (p.current == null && !p.loading && !p.failed) {
          return const SizedBox.shrink();
        }
        return Material(
          color: Theme.of(c).colorScheme.surfaceContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.loading) const LinearProgressIndicator(),
              if (p.failed)
                Text(
                  c.t(
                    'Audio gagal. Periksa koneksi, lalu putar ulang.',
                    'Audio failed. Check connection, then retry.',
                  ),
                ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text('${c.t('Ayat', 'Verse')} ${p.current?.ref ?? ''}'),
                  IconButton(
                    tooltip: c.t('Sebelumnya', 'Previous'),
                    onPressed: p.current == null ? null : () => p.move(-1),
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    tooltip: c.t('Putar / jeda', 'Play / pause'),
                    onPressed: p.current == null ? null : p.toggle,
                    icon: Icon(p.playing ? Icons.pause : Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: c.t('Berikutnya', 'Next'),
                    onPressed: p.current == null ? null : () => p.move(1),
                    icon: const Icon(Icons.skip_next),
                  ),
                  IconButton(
                    tooltip: c.t('Hentikan', 'Stop'),
                    onPressed: p.stop,
                    icon: const Icon(Icons.stop),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
