import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/offline_recitation/controller.dart';
import '../../services/offline_recitation/device.dart';
import '../../services/offline_recitation/domain.dart';
import '../../services/quran_repository.dart';
import '../../widgets/common.dart';

String recitationReason(BuildContext c, String code) => switch (code) {
  'permissionDenied' => c.t(
    'Izin mikrofon ditolak. Izinkan di pengaturan Android atau lanjutkan latihan manual.',
    'Microphone permission denied. Allow it in Android settings or continue manual practice.',
  ),
  'unsupported' => c.t(
    'Fitur ini tersedia di Android. Latihan manual tetap tersedia.',
    'This feature is available on Android. Manual practice remains available.',
  ),
  'modelMissing' || 'modelCorrupt' => c.t(
    'Aset model belum lengkap atau rusak. Pasang APK yang menyertakan model terverifikasi.',
    'Model assets are missing or damaged. Install an APK with the verified model.',
  ),
  'silence' => c.t(
    'Suara terlalu pelan atau hening. Coba rekam lebih dekat ke mikrofon.',
    'Audio is too quiet or silent. Try recording closer to the microphone.',
  ),
  'clipped' => c.t(
    'Rekaman terdistorsi. Jauhkan mikrofon dan ulangi.',
    'Recording is distorted. Move the microphone farther away and retry.',
  ),
  'invalidAudio' => c.t(
    'Audio harus mono 16 kHz, sekitar 1–20 detik.',
    'Audio must be mono 16 kHz, about 1–20 seconds.',
  ),
  'qualityNotValidated' => c.t(
    'Akurasi model untuk tilawah dan ambang keyakinannya belum tervalidasi. Transkrip dapat keliru; tidak ada kata yang dinyatakan salah.',
    'Quran recitation accuracy and confidence thresholds are not validated. The transcript may be wrong; no word is judged incorrect.',
  ),
  'deleteFailed' => c.t(
    'Rekaman belum berhasil dihapus. Coba hapus kembali sebelum keluar.',
    'Recording could not be deleted. Retry deletion before leaving.',
  ),
  'emptyOrTooLong' || 'emptyTranscript' => c.t(
    'Transkrip kosong atau rentang terlalu panjang. Pilih ayat lebih pendek dan ulangi.',
    'Transcript is empty or the range is too long. Choose a shorter passage and retry.',
  ),
  _ => c.t(
    'Proses lokal belum berhasil. Tutup aplikasi lain bila memori terbatas, lalu coba lagi atau gunakan latihan manual.',
    'Local processing failed. Close other apps if memory is limited, then retry or use manual practice.',
  ),
};
String recitationStatusLabel(
  BuildContext c,
  RecitationStatus status,
) => switch (status) {
  RecitationStatus.detectedMatch => c.t('Sesuai terdeteksi', 'Detected match'),
  RecitationStatus.needsReview => c.t('Perlu diulang', 'Needs review'),
  RecitationStatus.unassessed => c.t('Belum dapat dinilai', 'Unable to assess'),
};

class OfflineRecitationPage extends StatefulWidget {
  const OfflineRecitationPage({super.key, required this.verses, this.device});
  final List<Verse> verses;
  final RecitationDevice? device;
  @override
  State<OfflineRecitationPage> createState() => _OfflineRecitationPageState();
}

class _OfflineRecitationPageState extends State<OfflineRecitationPage>
    with WidgetsBindingObserver {
  late final RecitationController controller;
  String sessionId = DateTime.now().microsecondsSinceEpoch.toString();
  bool saved = false, saving = false, leaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = RecitationController(
      widget.device ?? createRecitationDevice(),
      widget.verses,
    );
    controller.addListener(refresh);
    unawaited(controller.prepare());
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        [
          RecitationPhase.recording,
          RecitationPhase.starting,
        ].contains(controller.phase)) {
      unawaited(controller.cancel());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(refresh);
    controller.dispose();
    super.dispose();
  }

  bool get dirty =>
      controller.clip != null ||
      [
        RecitationPhase.starting,
        RecitationPhase.recording,
        RecitationPhase.processing,
        RecitationPhase.cancelling,
      ].contains(controller.phase) ||
      (controller.recognition != null && !saved);
  Future<void> leave() async {
    if (leaving || saving) return;
    final consent = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.t('Tinggalkan sesi?', 'Leave session?')),
        content: Text(
          c.t(
            'Rekaman dan hasil yang belum disimpan akan dihapus. Proses lokal yang berjalan perlu selesai sebelum resource dilepas.',
            'Recording and unsaved results will be deleted. A running local decode must finish before its resources are released.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.t('Lanjutkan', 'Continue')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.t('Hapus & keluar', 'Delete & leave')),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    setState(() => leaving = true);
    await controller.cancel();
    if (!mounted) return;
    if (controller.error != null) {
      setState(() => leaving = false);
      return;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext c) {
    final phase = controller.phase;
    final result = controller.alignment;
    return PopScope(
      canPop: !dirty || (leaving && phase == RecitationPhase.ready),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            c.t('AI Koreksi Hafalan Offline', 'Offline recitation assistant'),
          ),
        ),
        body: padded([
          Text(
            c.t(
              'Eksperimental • diproses di perangkat',
              'Experimental • processed on device',
            ),
            style: Theme.of(c).textTheme.titleMedium,
          ),
          Text(
            c.t(
              'Tidak mengirim suara atau transkrip ke server. Model dibundel sekitar 100 MB dan disiapkan lokal pada penggunaan pertama. Memori dan waktu proses bergantung perangkat.',
              'No audio or transcripts are sent to a server. The bundled model is about 100 MB and is prepared locally on first use. Memory and processing time depend on your device.',
            ),
          ),
          Text(
            c.t(
              'Bukan penilaian tajwid/makhraj atau pengganti guru. Pilih 1–3 ayat pendek; batas rekaman 20 detik.',
              'Not a tajwid/makhraj assessment or a replacement for a teacher. Choose 1–3 short verses; recording is limited to 20 seconds.',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${c.t('Rentang', 'Range')}: ${widget.verses.isEmpty ? '—' : '${widget.verses.first.ref} – ${widget.verses.last.ref}'}',
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                recitationReason(c, controller.error!),
                semanticsLabel: recitationReason(c, controller.error!),
              ),
            ),
          if ([
            RecitationPhase.preparing,
            RecitationPhase.starting,
            RecitationPhase.processing,
            RecitationPhase.cancelling,
          ].contains(phase)) ...[
            const LinearProgressIndicator(),
            Text(
              phase == RecitationPhase.processing
                  ? c.t(
                      'Mengenali bacaan di perangkat…',
                      'Recognizing locally…',
                    )
                  : phase == RecitationPhase.cancelling
                  ? c.t(
                      'Membatalkan; menunggu proses lokal melepaskan resource…',
                      'Cancelling; waiting for local resources to be released…',
                    )
                  : c.t('Menyiapkan…', 'Preparing…'),
            ),
            if (phase == RecitationPhase.processing)
              OutlinedButton(
                onPressed: controller.cancel,
                child: Text(c.t('Batalkan proses', 'Cancel processing')),
              ),
          ],
          if (phase == RecitationPhase.ready) ...[
            Text(
              c.t(
                'Izin mikrofon diminta saat mulai merekam. Rekaman dihapus setelah diproses atau dibatalkan.',
                'Microphone permission is requested when recording starts. Audio is deleted after processing or cancellation.',
              ),
            ),
            FilledButton.icon(
              onPressed:
                  widget.verses.isEmpty ||
                      referenceWords(widget.verses).length > 400
                  ? null
                  : () async {
                      saved = false;
                      sessionId = DateTime.now().microsecondsSinceEpoch
                          .toString();
                      await perform(c, () async {
                        await Session.of(c).player.stop();
                        if (mounted) await controller.start();
                      });
                    },
              icon: const Icon(Icons.mic),
              label: Text(c.t('Mulai rekam', 'Start recording')),
            ),
            if (referenceWords(widget.verses).length > 400)
              Text(
                c.t(
                  'Rentang terlalu panjang. Kembali dan pilih ayat lebih sedikit.',
                  'Range is too long. Go back and select fewer verses.',
                ),
              ),
          ],
          if (phase == RecitationPhase.recording) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                '${c.t('Merekam', 'Recording')}: ${controller.seconds} / 20 s',
              ),
            ),
            FilledButton(
              onPressed: controller.stop,
              child: Text(c.t('Hentikan rekaman', 'Stop recording')),
            ),
            OutlinedButton(
              onPressed: controller.cancel,
              child: Text(c.t('Batal & hapus', 'Cancel & delete')),
            ),
          ],
          if (phase == RecitationPhase.recorded) ...[
            OutlinedButton(
              onPressed: controller.play,
              child: Text(c.t('Dengarkan rekaman', 'Play recording')),
            ),
            FilledButton(
              onPressed: controller.process,
              child: Text(c.t('Proses offline', 'Process offline')),
            ),
            TextButton(
              onPressed: controller.cancel,
              child: Text(c.t('Hapus rekaman', 'Delete recording')),
            ),
          ],
          if (phase == RecitationPhase.error)
            OutlinedButton(
              onPressed: () async {
                await controller.cancel();
                if (controller.error == null) await controller.prepare();
              },
              child: Text(c.t('Coba lagi', 'Retry')),
            ),
          if (phase == RecitationPhase.result && result != null) ...[
            Text(
              recitationStatusLabel(c, result.status),
              style: Theme.of(c).textTheme.headlineSmall,
            ),
            Text(recitationReason(c, result.reason)),
            Text(
              c.t(
                'Transkrip model (bisa keliru)',
                'Model transcript (may be wrong)',
              ),
            ),
            SelectableText(
              controller.recognition!.text,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabic.copyWith(fontSize: 26, height: 1.8),
            ),
            for (final difference in result.differences)
              ListTile(
                title: Text(
                  '${difference.reference?.ref} • ${difference.reference?.original ?? ''}',
                ),
                subtitle: Text(
                  '${c.t('Dugaan perbedaan', 'Possible difference')}: ${difference.kind} • ${difference.heard}',
                ),
              ),
            Text(
              c.t(
                'Simpan hanya ringkasan status dan rentang ayat ke perangkat; suara dan transkrip tidak disimpan. Status hafalan tidak diubah.',
                'Save only status and verse range on this device; audio and transcript are not retained. Memorization status is unchanged.',
              ),
            ),
            FilledButton(
              onPressed: saved || saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      await perform(c, () async {
                        await Session.of(c).store.update((next) {
                          final summaries = List<dynamic>.from(
                            next['offlineRecitationSessions'] as List? ?? [],
                          );
                          if (!summaries.any((s) => s['id'] == sessionId)) {
                            summaries.insert(0, {
                              'id': sessionId,
                              'time': DateTime.now().toIso8601String(),
                              'refs': widget.verses.map((v) => v.ref).toList(),
                              'status': result.status.name,
                              'reason': result.reason,
                              'model': controller.recognition!.model,
                            });
                          }
                          next['offlineRecitationSessions'] = summaries;
                        });
                        if (mounted) setState(() => saved = true);
                      });
                      if (mounted) setState(() => saving = false);
                    },
              child: Text(
                saved
                    ? c.t('Ringkasan tersimpan', 'Summary saved')
                    : c.t('Simpan ringkasan', 'Save summary'),
              ),
            ),
            OutlinedButton(
              onPressed: saving ? null : controller.cancel,
              child: Text(c.t('Rekam ulang', 'Record again')),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            c.t('Ayat referensi', 'Reference verses'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          for (final verse in widget.verses) ...[
            Text(verse.ref),
            SelectableText(
              verse.arabic,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabic.copyWith(fontSize: 28, height: 2),
            ),
          ],
        ]),
      ),
    );
  }
}
