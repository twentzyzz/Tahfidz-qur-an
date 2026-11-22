import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import '../../services/verse_quiz.dart';
import '../../services/quiz_history_store.dart';
import 'quiz_history_page.dart';

class VerseQuizPage extends StatefulWidget {
  const VerseQuizPage({super.key});

  @override
  State<VerseQuizPage> createState() => _VerseQuizPageState();
}

class _VerseQuizPageState extends State<VerseQuizPage> {
  int _surah = 1;
  Future<List<Verse>>? _versesFuture;
  List<VerseQuizQuestion> _questions = const [];
  int _index = 0;
  int _score = 0;
  Verse? _selected;
  bool _saving = false;
  String? _saveError;
  String? _attemptId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _versesFuture ??= Session.of(context).quran.surah(_surah);
  }

  void _selectSurah(int number) {
    setState(() {
      _surah = number;
      _versesFuture = Session.of(context).quran.surah(number);
      _questions = const [];
      _index = 0;
      _score = 0;
      _selected = null;
      _saving = false;
      _saveError = null;
      _attemptId = null;
    });
  }

  void _start(List<Verse> verses) {
    final questions = VerseQuiz.generate(verses);
    setState(() {
      _questions = questions;
      _index = 0;
      _score = 0;
      _selected = null;
      _saving = false;
      _saveError = null;
      _attemptId = null;
    });
  }

  void _answer(Verse verse) {
    if (_selected != null) return;
    setState(() {
      _selected = verse;
      if (_questions[_index].isCorrect(verse)) _score++;
    });
  }

  Future<void> _next() async {
    if (_selected == null || _saving) return;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }

    // A result is persisted only after the last question has an answer.
    // Reuse the attempt ID on retry so a double tap cannot duplicate it.
    final id = _attemptId ?? DateTime.now().microsecondsSinceEpoch.toString();
    _attemptId = id;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await Session.of(context).store.saveQuizAttempt(
        id: id,
        surah: _surah,
        correct: _score,
        total: _questions.length,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _index++;
        _selected = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = context.t(
          'Gagal menyimpan nilai. Coba lagi.',
          'Could not save your score. Please retry.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quran = Session.of(context).quran;
    final eligible = quran.chapters.where((s) => s.count >= 5).toList();
    final theme = Theme.of(context);
    final finished = _questions.isNotEmpty && _index >= _questions.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('Kuis Sambung Ayat', 'Next Verse Quiz'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  context.t(
                    'Latih ingatan dengan memilih ayat berikutnya. Semua pilihan berasal dari teks Al-Qur’an offline.',
                    'Practice by choosing the next verse. All choices use offline Quran text.',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('quiz-history-open'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const QuizHistoryPage()),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: Text(context.t('Riwayat Nilai Kuis', 'Quiz score history')),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  key: const Key('quiz-surah-selector'),
                  initialValue: _surah,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.t('Pilih surah', 'Select surah'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final chapter in eligible)
                      DropdownMenuItem<int>(
                        value: chapter.number,
                        child: Text(
                          '${chapter.number}. ${chapter.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (number) {
                    if (number != null) _selectSurah(number);
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Verse>>(
                  future: _versesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(
                            context.t('Gagal memuat ayat offline.', 'Could not load offline verses.'),
                            style: TextStyle(color: theme.colorScheme.error),
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
                    if (finished) {
                      return Card(
                        key: const Key('quiz-finished'),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  size: 48, color: theme.colorScheme.primary),
                              const SizedBox(height: 12),
                              Text(
                                context.t('Kuis selesai!', 'Quiz complete!'),
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$_score / ${_questions.length}',
                                key: const Key('quiz-score'),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.t(
                                  'Nilai tersimpan di perangkat ini. Status hafalan tidak berubah.',
                                  'Score saved on this device. Memorization status is unchanged.',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => _start(verses),
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(context.t('Ulangi kuis', 'Try again')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (_questions.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                context.t(
                                  '5 pertanyaan acak • 4 pilihan jawaban',
                                  '5 random questions • 4 choices',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                key: const Key('quiz-start'),
                                onPressed: () => _start(verses),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(context.t('Mulai kuis', 'Start quiz')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final question = _questions[_index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.t(
                            'Pertanyaan ${_index + 1} dari ${_questions.length} • Skor $_score',
                            'Question ${_index + 1} of ${_questions.length} • Score $_score',
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: _index / _questions.length),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.t(
                                    'Apa ayat setelah ${quran.chapters[_surah - 1].name} ayat ${question.prompt.number}?',
                                    'Which verse follows ${quran.chapters[_surah - 1].name} verse ${question.prompt.number}?',
                                  ),
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 18),
                                SelectableText(
                                  question.prompt.arabic,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.arabic.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 27,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final option in question.options) ...[
                          Card(
                            color: _selected == null
                                ? null
                                : question.isCorrect(option)
                                    ? theme.colorScheme.primaryContainer
                                    : _selected!.ref == option.ref
                                        ? theme.colorScheme.errorContainer
                                        : null,
                            child: InkWell(
                              key: ValueKey('quiz-option-${option.ref}'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: _selected == null ? () => _answer(option) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.arabic,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: AppTypography.arabic.copyWith(
                                          fontSize: 23,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (_selected != null && question.isCorrect(option))
                                      const Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: Icon(Icons.check_circle_rounded),
                                      ),
                                    if (_selected != null &&
                                        _selected!.ref == option.ref &&
                                        !question.isCorrect(option))
                                      const Padding(
                                        padding: EdgeInsets.only(left: 12),
                                        child: Icon(Icons.cancel_rounded),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (_selected != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            question.isCorrect(_selected!)
                                ? context.t('Benar! Masya Allah.', 'Correct! Masha Allah.')
                                : context.t(
                                    'Belum tepat. Jawaban benar adalah ayat ${question.answer.number}.',
                                    'Not quite. The correct answer is verse ${question.answer.number}.',
                                  ),
                            key: const Key('quiz-feedback'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            key: const Key('quiz-next'),
                            onPressed: _saving ? null : _next,
                            child: Text(_saving
                                ? context.t('Menyimpan...', 'Saving...')
                                : _index == _questions.length - 1
                                ? context.t('Lihat hasil', 'See results')
                                : context.t('Pertanyaan berikutnya', 'Next question')),
                          ),
                          if (_saveError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _saveError!,
                              key: const Key('quiz-save-error'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
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
