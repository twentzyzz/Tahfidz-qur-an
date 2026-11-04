import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/player_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/mini_player.dart';
import 'qari_avatar.dart';
export 'qari_avatar.dart';

class QariPage extends StatefulWidget {
  const QariPage({super.key});
  @override
  State<QariPage> createState() => _QariPageState();
}

class _QariPageState extends State<QariPage> {
  String query = '';
  bool onlyFavorites = false;
  bool busy = false;

  Future<void> select(String id, {bool preview = false}) async {
    if (busy) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    final session = Session.of(context);
    await perform(context, () async {
      if (preview) {
        final verses = await session.quran.surah(1);
        await session.player.play([verses.first], id, 1);
      } else {
        await session.store.set('qari', id);
        await session.player.changeQari(id);
      }
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) {
    final s = Session.of(c);
    final cs = Theme.of(c).colorScheme;
    final selected = s.store.get('qari', '05');
    final favorites = s.store.map('favoriteQaris');
    final results = qaris.entries
        .where(
          (q) =>
              q.value.toLowerCase().contains(query.trim().toLowerCase()) &&
              (!onlyFavorites || favorites[q.key] == true),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Pilih Qari', 'Choose a reciter'))),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                c.t(
                  'Bacaan yang menemani harimu.',
                  'A recitation for your day.',
                ),
                style: Theme.of(c).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                c.t(
                  'Dengarkan contoh Al-Fatihah, lalu pilih suara yang nyaman untuk menghafal.',
                  'Preview Al-Fatihah and choose a voice for your memorization.',
                ),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: c.t('Cari qari', 'Search reciters'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(c.t('Favorit', 'Favorites')),
                    selected: onlyFavorites,
                    avatar: const Icon(Icons.favorite_border_rounded, size: 18),
                    onSelected: (v) => setState(() => onlyFavorites = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    c.t(
                      'Tidak ada qari yang cocok. Coba nama lain atau nonaktifkan filter favorit.',
                      'No matching reciters. Try another name or turn off the favorites filter.',
                    ),
                  ),
                ),
              for (final q in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: q.key == selected ? cs.primaryContainer : cs.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: busy ? null : () => select(q.key),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  QariAvatar(name: q.value),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.value,
                                          style: Theme.of(c)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          q.key == selected
                                              ? c.t(
                                                  'Qari aktif · Audio tersedia',
                                                  'Selected · Audio available',
                                                )
                                              : c.t(
                                                  'Audio tersedia',
                                                  'Audio available',
                                                ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    q.key == selected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: cs.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => select(q.key, preview: true),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(c.t('Coba audio', 'Preview audio')),
                              ),
                              IconButton(
                                tooltip: favorites[q.key] == true
                                    ? c.t('Hapus favorit', 'Remove favorite')
                                    : c.t(
                                        'Jadikan Qari Favorit',
                                        'Favorite reciter',
                                      ),
                                isSelected: favorites[q.key] == true,
                                onPressed: () => perform(c, () async {
                                  final next = s.store.map('favoriteQaris');
                                  if (next[q.key] == true) {
                                    next.remove(q.key);
                                  } else {
                                    next[q.key] = true;
                                  }
                                  await s.store.set('favoriteQaris', next);
                                }),
                                icon: const Icon(Icons.favorite_border_rounded),
                                selectedIcon: const Icon(
                                  Icons.favorite_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: c,
                  builder: (c) => AlertDialog(
                    title: Text(c.t('Kredit foto', 'Photo credit')),
                    content: const SingleChildScrollView(
                      child: SelectableText(
                        'Yasser Al-Dosari — MAL MALDIVE, 7 April 2024.\nCC BY-SA 4.0\nhttps://creativecommons.org/licenses/by-sa/4.0/\n\nhttps://commons.wikimedia.org/wiki/File:Yasser_Al-Dosari.jpg\n\nFoto asli disimpan lokal; tampilan dipotong menjadi lingkaran. Qari lain menggunakan avatar inisial, bukan foto asli. / Original photograph stored locally; displayed with circular cropping. Other reciters use initials avatars.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: Text(c.t('Tutup', 'Close')),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.info_outline_rounded),
                label: Text(
                  c.t('Kredit foto & avatar', 'Photo & avatar credits'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
