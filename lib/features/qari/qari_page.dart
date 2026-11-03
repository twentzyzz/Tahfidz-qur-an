import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/player_controller.dart';
import '../../widgets/common.dart';

/// Visual fallback only: initials are not photographs of real reciters.
class QariAvatar extends StatelessWidget {
  const QariAvatar({super.key, required this.name, this.size = 52});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.first.substring(0, 1) + (parts.length > 1 ? parts.last.substring(0, 1) : '')).toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.t('Avatar inisial, bukan foto qari', 'Initials avatar, not a reciter photograph'),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Text(initials, style: TextStyle(fontSize: size * .26, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class QariPage extends StatelessWidget {
  const QariPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = session.store.get('qari', '05');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Pilih Qari', 'Choose a reciter')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.headphones_rounded, size: 42, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.t('Dengarkan dengan qari pilihanmu', 'Listen with your favorite reciter'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(context.t(
                            'Ketuk putar untuk mencoba bacaan Al-Fatihah. Foto asli akan ditampilkan setelah izin penggunaan terverifikasi.',
                            'Tap play to preview Al-Fatihah. Real portraits will be shown when usage rights are verified.',
                          ), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(context.t('Qari tersedia', 'Available reciters'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(context.t('6 suara dengan sumber audio yang tersedia', '6 reciters with available audio sources'),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              for (final q in qaris.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: q.key == selected ? scheme.primaryContainer.withValues(alpha: .55) : scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: q.key == selected ? scheme.primary : scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: QariAvatar(name: q.value),
                        title: Text(q.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(q.key == selected
                            ? context.t('Qari aktif', 'Selected reciter')
                            : context.t('Ketuk untuk memilih', 'Tap to select')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              tooltip: context.t('Coba audio', 'Preview audio'),
                              onPressed: () => perform(context, () async {
                                final verses = await session.quran.surah(1);
                                if (verses.isNotEmpty) await session.player.play([verses.first], q.key, 1);
                              }),
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                            const SizedBox(width: 6),
                            Icon(q.key == selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: q.key == selected ? scheme.primary : scheme.outline),
                          ],
                        ),
                        onTap: () => perform(context, () async {
                          await session.store.set('qari', q.key);
                          if (session.player.current != null) {
                            await session.player.play(session.player.verses, q.key, session.player.repeats);
                          }
                        }),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
