import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/audio_offline_service.dart';
import '../../services/player_controller.dart';

/// Download individual surahs for one qari at a time. The player
/// automatically prefers the resulting private device files.
class OfflineAudioPage extends StatefulWidget {
  const OfflineAudioPage({super.key});

  @override
  State<OfflineAudioPage> createState() => _OfflineAudioPageState();
}

class _OfflineAudioPageState extends State<OfflineAudioPage> {
  bool initialized = false;
  late String voice;
  late Future<OfflineAudioSnapshot> summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    voice = Session.of(context).store.get<String>('qari', '05');
    summary = Session.of(context).audioOffline.snapshot(voice);
    initialized = true;
  }

  void refresh() {
    setState(() {
      summary = Session.of(context).audioOffline.snapshot(voice);
    });
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> download(int surah) async {
    final s = Session.of(context);
    final selectedVoice = voice;
    try {
      final verses = await s.quran.surah(surah);
      await s.audioOffline.downloadSurah(verses, selectedVoice);
      if (!mounted) return;
      message(s.audioOffline.cancelRequested
          ? context.t('Unduhan dibatalkan. Ayat yang selesai tetap tersimpan.',
                      'Download cancelled. Completed verses are kept.')
          : context.t('Audio berhasil disimpan di perangkat.',
                      'Audio saved to this device.'));
    } catch (_) {
      if (!mounted) return;
      message(context.t(
        'Unduhan gagal. Periksa internet, penyimpanan, atau sumber audio.',
        'Download failed. Check the connection, storage, or audio source.',
      ));
    } finally {
      if (mounted) refresh();
    }
  }

  Future<void> remove(int surah) async {
    final s = Session.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t('Hapus audio offline?', 'Remove offline audio?')),
        content: Text(dialogContext.t(
          'Hanya audio surah dan qari ini yang dihapus. Progres hafalan aman.',
          'Only this reciter and chapter audio will be deleted. Memorization progress stays.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.t('Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.t('Hapus', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await s.audioOffline.deleteSurah(surah, voice);
      if (mounted) refresh();
    } catch (_) {
      message(context.t('Gagal menghapus audio.', 'Unable to delete audio.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Session.of(context);
    final offline = s.audioOffline;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Audio murottal offline', 'Offline Quran audio')),
      ),
      body: ListenableBuilder(
        listenable: offline,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.headphones_rounded, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.t('Unduh per surah & qari',
                                    'Download by chapter and reciter'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(context.t(
                          'Unduhan disimpan khusus di perangkat ini dan dipakai otomatis saat memutar ayat. Untuk unduh, gunakan Wi-Fi bila memungkinkan.',
                          'Downloads stay private on this device and are played automatically. Prefer Wi-Fi for downloads.',
                        )),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey('offline-qari-' + voice),
                          initialValue: voice,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.record_voice_over_rounded),
                            labelText: context.t('Pilih qari', 'Choose reciter'),
                          ),
                          items: [
                            for (final q in qaris.entries)
                              DropdownMenuItem(value: q.key, child: Text(q.value)),
                          ],
                          onChanged: offline.isDownloading ? null : (next) {
                            if (next == null) return;
                            setState(() {
                              voice = next;
                              summary = offline.snapshot(voice);
                            });
                          },
                        ),
                        if (offline.isDownloading) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: offline.total == 0
                                ? null
                                : offline.completed / offline.total,
                          ),
                          const SizedBox(height: 8),
                          Text(context.t(
                            'Tersimpan: ',
                            'Saved: ',
                          ) + offline.completed.toString() +
                              ' / ' + offline.total.toString()),
                          TextButton.icon(
                            onPressed: offline.cancelRequested
                                ? null
                                : offline.cancel,
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(context.t('Batalkan unduhan', 'Cancel download')),
                          ),
                        ],
                        if (offline.error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            context.t(
                              'Unduhan terakhir gagal. File yang selesai tetap tersedia.',
                              'Last download failed. Completed files are still available.',
                            ),
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          context.t(
                            'Audio berasal dari EQuran.id. File hanya disimpan lokal; aplikasi tidak menyertakan atau membagikan ulang rekaman.',
                            'Audio comes from EQuran.id. Files are stored locally only; no recordings are bundled or redistributed.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!offline.supported)
                  Text(context.t(
                    'Unduhan offline belum didukung pada platform ini.',
                    'Offline downloads are not supported on this platform.',
                  ))
                else
                  FutureBuilder<OfflineAudioSnapshot>(
                    future: summary,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Text(context.t(
                              'Penyimpanan audio tidak dapat dibuka.',
                              'Unable to access audio storage.',
                            )),
                            TextButton(
                              onPressed: refresh,
                              child: Text(context.t('Coba lagi', 'Retry')),
                            ),
                          ],
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final saved = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              context.t('Penyimpanan qari ini', 'Reciter storage') +
                                  ': ' +
                                  (saved.bytes / (1024 * 1024)).toStringAsFixed(1) +
                                  ' MB',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          for (final chapter in s.quran.chapters)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        saved.countFor(chapter.number) == chapter.count
                                            ? Icons.offline_pin_rounded
                                            : Icons.menu_book_outlined,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chapter.name,
                                              style: Theme.of(context)
                                                  .textTheme.titleSmall
                                                  ?.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              saved.countFor(chapter.number).toString() +
                                                  ' / ' + chapter.count.toString() +
                                                  ' ' + context.t('ayat tersimpan', 'verses saved'),
                                              style: Theme.of(context).textTheme.bodySmall
                                                  ?.copyWith(color: colors.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (saved.countFor(chapter.number) > 0)
                                        IconButton(
                                          tooltip: context.t(
                                            'Hapus unduhan surah', 'Delete chapter audio'),
                                          onPressed: offline.isDownloading
                                              ? null
                                              : () => remove(chapter.number),
                                          icon: const Icon(Icons.delete_outline_rounded),
                                        ),
                                      IconButton(
                                        tooltip: saved.countFor(chapter.number) == chapter.count
                                            ? context.t('Sudah offline', 'Available offline')
                                            : context.t('Unduh audio surah', 'Download chapter audio'),
                                        onPressed: offline.isDownloading ||
                                                saved.countFor(chapter.number) == chapter.count
                                            ? null
                                            : () => download(chapter.number),
                                        icon: Icon(saved.countFor(chapter.number) ==
                                                chapter.count
                                            ? Icons.check_circle_rounded
                                            : Icons.download_for_offline_outlined),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
