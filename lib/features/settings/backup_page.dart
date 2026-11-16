import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  static const _channel = MethodChannel('id.tahfidz.tahfidz_quran/backup');
  final input = TextEditingController();
  BackupPreview? preview;
  bool busy = false;
  bool get android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> exportFile() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final content = BackupService.export(Session.of(context).store);
      final name = 'tahfidz-quran-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json';
      final saved = await _channel.invokeMethod<bool>('saveBackup', {
        'content': content,
        'fileName': name,
      });
      if (saved == true && mounted) {
        message(context.t('File backup berhasil disimpan.', 'Backup file saved.'));
      }
    } catch (_) {
      message(context.t('Gagal menyimpan file backup.', 'Could not save backup file.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> copyBackup() async {
    try {
      await Clipboard.setData(ClipboardData(
        text: BackupService.export(Session.of(context).store),
      ));
      if (mounted) {
        message(context.t(
          'Kode backup disalin. Simpan di tempat aman.',
          'Backup code copied. Keep it somewhere safe.',
        ));
      }
    } catch (_) {
      message(context.t('Gagal menyalin backup.', 'Could not copy backup.'));
    }
  }

  Future<void> openFile() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final text = await _channel.invokeMethod<String>('openBackup');
      if (text == null || !mounted) return;
      check(text);
    } catch (_) {
      message(context.t('Gagal membuka file backup.', 'Could not open backup file.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void check(String text) {
    try {
      final parsed = BackupService.inspect(text);
      setState(() {
        preview = parsed;
        input.text = text;
      });
      message(context.t('Backup valid. Periksa ringkasannya.', 'Backup valid. Review the summary.'));
    } catch (error) {
      setState(() => preview = null);
      message(error is FormatException
          ? error.message
          : context.t('Isi backup tidak valid.', 'Invalid backup data.'));
    }
  }

  Future<void> restore() async {
    final candidate = preview;
    if (candidate == null || busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Pulihkan backup?', 'Restore backup?')),
        content: Text(context.t(
          'Semua progres, bookmark, riwayat, dan pengaturan lokal saat ini akan DIGANTI oleh isi backup. Tindakan ini tidak dapat dibatalkan. Simpan backup data saat ini terlebih dahulu.',
          'All current local progress, bookmarks, history and settings will be REPLACED. This cannot be undone. Back up your current data first.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('Ya, pulihkan', 'Restore now')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final s = Session.of(context);
      await BackupService.restore(s.store, candidate);
      try {
        await s.prayer.schedule();
      } catch (_) {
        // The user data was already restored. Scheduling will retry on resume.
      }
      if (!mounted) return;
      setState(() => preview = null);
      message(context.t('Data berhasil dipulihkan.', 'Backup restored.'));
    } catch (_) {
      message(context.t('Gagal memulihkan data. Data lama tetap tersimpan.', 'Restore failed. Original data kept.'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Session.of(context).store;
    final progress = store.map('progress');
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Backup & Pulihkan', 'Backup & Restore'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064735), Color(0xFF087F5B)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFC5A064)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_done_outlined,
                    color: Color(0xFFF2D9A1), size: 34),
                const SizedBox(height: 12),
                Text(
                  context.t('Hafalanmu berharga', 'Your memorization matters'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(
                    'Simpan salinan data di luar aplikasi agar tidak hilang saat berganti perangkat.',
                    'Keep a copy outside the app so it survives device changes.',
                  ),
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('Data di perangkat ini', 'Data on this device'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    '${progress.values.where((v) => v == 'done').length} ${context.t('ayat hafal', 'verses memorized')} • ${store.map('bookmarks').length} bookmark',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  if (android)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : exportFile,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: Text(context.t('Simpan file backup (.json)', 'Save backup file (.json)')),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : copyBackup,
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(context.t('Salin kode backup', 'Copy backup code')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.t('Pulihkan data', 'Restore data'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    context.t('Pilih file JSON atau tempel kode backup yang pernah disimpan.', 'Choose a JSON file or paste your saved backup code.'),
                  ),
                  const SizedBox(height: 12),
                  if (android)
                    OutlinedButton.icon(
                      onPressed: busy ? null : openFile,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(context.t('Pilih file backup', 'Choose backup file')),
                    ),
                  TextField(
                    controller: input,
                    onChanged: (_) => setState(() => preview = null),
                    maxLines: 4,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: context.t('Kode backup', 'Backup code'),
                      hintText: context.t('Tempel JSON di sini', 'Paste JSON here'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: busy ? null : () => check(input.text),
                    child: Text(context.t('Periksa backup', 'Validate backup')),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${context.t('Tanggal backup', 'Backup date')}: ${preview!.createdAt.toLocal().toString().substring(0, 16)}',
                    ),
                    Text(
                      '${preview!.memorized} ${context.t('ayat hafal', 'memorized')} • ${preview!.learning} ${context.t('dipelajari', 'learning')} • ${preview!.bookmarks} bookmark',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: busy ? null : restore,
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: Text(context.t('Pulihkan backup ini', 'Restore this backup')),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t(
              'Backup berisi data lokal termasuk progres, bookmark, riwayat, target, dan pengaturan. Simpan file secara pribadi. Backup tidak diunggah ke server.',
              'The backup contains local progress, bookmarks, history, goals and settings. Keep it private. Nothing is uploaded to a server.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
