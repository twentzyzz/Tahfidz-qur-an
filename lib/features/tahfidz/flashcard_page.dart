import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/flashcard_store.dart';
import '../../services/quran_repository.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  int _surah = 1;
  Future<List<Verse>>? _verses;
  FlashcardSession? _session;
  bool _revealed = false;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verses ??= Session.of(context).quran.surah(_surah);
  }

  void _selectSurah(int number) {
    setState(() {
      _surah = number;
      _verses = Session.of(context).quran.surah(number);
      _session = null;
      _revealed = false;
      _error = null;
    });
  }

  void _start(List<Verse> verses) {
    final deck = FlashcardDeck.generate(
      verses,
      Session.of(context).store.flashcardRatings,
    );
    setState(() {
      _session = FlashcardSession(deck);
      _revealed = false;
      _error = null;
    });
  }

  Future<void> _rate(bool remembered) async {
    final current = _session?.current;
    if (current == null || !_revealed || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Only publish the UI result once the on-device write succeeds.
      // Flashcard ratings never change the memorized/learning status.
      await Session.of(context).store.rateFlashcard(
        current.ref,
        remembered: remembered,
      );
      if (!mounted) return;
      setState(() {
        _session!.rate(remembered: remembered);
        _revealed = false;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.t(
          'Gagal menyimpan penilaian. Coba lagi.',
          'Could not save your rating. Try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quran = Session.of(context).quran;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = _session;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('Flashcard Hafalan', 'Memorization flashcards'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  context.t(
                    'Coba ingat teks Arab dari nomor ayat dan terjemahannya. Balik kartu untuk melihat jawabannya.',
                    'Recall the Arabic verse using its number and translation. Reveal the card to check.',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  key: const Key('flashcard-surah-selector'),
                  initialValue: _surah,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.t('Pilih surah', 'Select surah'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final chapter in quran.chapters)
                      DropdownMenuItem<int>(
                        value: chapter.number,
                        child: Text(
                          '${chapter.number}. ${chapter.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) _selectSurah(value);
                        },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Verse>>(
                  future: _verses,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(
                            context.t('Gagal memuat ayat offline.', 'Could not load offline verses.'),
                            style: TextStyle(color: colors.error),
                          ),
                          TextButton(
                            onPressed: () => _selectSurah(_surah),
                            child: Text(context.t('Coba lagi', 'Retry')),
                          ),
                        ],
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final verses = snapshot.data!;
                    if (session == null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              Icon(Icons.style_outlined, size: 44, color: colors.primary),
                              const SizedBox(height: 12),
                              Text(
                                context.t(
                                  '10 kartu per sesi (atau semua ayat jika kurang dari 10). Ayat yang sulit diprioritaskan.',
                                  '10 cards per session (or all verses if fewer). Difficult verses come first.',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                key: const Key('flashcard-start'),
                                onPressed: () => _start(verses),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(context.t('Mulai flashcard', 'Start flashcards')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (session.isFinished) {
                      return Card(
                        key: const Key('flashcard-finished'),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              Icon(Icons.task_alt_rounded, size: 48, color: colors.primary),
                              const SizedBox(height: 12),
                              Text(context.t('Latihan selesai!', 'Practice complete!'),
                                  style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 10),
                              Text(
                                context.t(
                                  'Ingat: ${session.remembered} • Ulangi: ${session.again}',
                                  'Remembered: ${session.remembered} • Again: ${session.again}',
                                ),
                                key: const Key('flashcard-score'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.t(
                                  'Ini penilaian diri, bukan penilaian tajwid atau hafalan otomatis.',
                                  'These are self-ratings, not automated tajweed or memorization scores.',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                key: const Key('flashcard-repeat'),
                                onPressed: () => _start(verses),
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(context.t('Latihan lagi', 'Practice again')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final verse = session.current!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.t(
                            'Kartu ${session.completed + 1} dari ${session.total}',
                            'Card ${session.completed + 1} of ${session.total}',
                          ),
                          key: const Key('flashcard-progress'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: session.total == 0
                              ? 0
                              : session.completed / session.total,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          key: const Key('flashcard-card'),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${quran.chapters[_surah - 1].name} • ${context.t('Ayat', 'Verse')} ${verse.number}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 14),
                                Text(verse.translation, style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 20),
                                if (!_revealed)
                                  FilledButton.icon(
                                    key: const Key('flashcard-reveal'),
                                    onPressed: () => setState(() => _revealed = true),
                                    icon: const Icon(Icons.visibility_rounded),
                                    label: Text(context.t('Lihat jawaban Arab', 'Reveal Arabic answer')),
                                  )
                                else ...[
                                  Text(
                                    verse.arabic,
                                    key: const Key('flashcard-answer'),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    style: AppTypography.arabic.copyWith(
                                      fontSize: 26,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    context.t(
                                      'Apakah kamu berhasil mengingat ayatnya?',
                                      'Did you remember this verse?',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        key: const Key('flashcard-again'),
                                        onPressed: _saving ? null : () => _rate(false),
                                        icon: const Icon(Icons.replay_rounded),
                                        label: Text(context.t('Ulangi', 'Again')),
                                      ),
                                      FilledButton.icon(
                                        key: const Key('flashcard-remembered'),
                                        onPressed: _saving ? null : () => _rate(true),
                                        icon: const Icon(Icons.check_rounded),
                                        label: Text(context.t('Ingat', 'Remembered')),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            key: const Key('flashcard-save-error'),
                            style: TextStyle(color: colors.error),
                          ),
                        ],
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
