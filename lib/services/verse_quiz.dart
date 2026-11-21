import 'dart:math';

import 'quran_repository.dart';

/// A question asks for the verse immediately following [prompt].
/// Choices always come from the same verified offline surah dataset.
class VerseQuizQuestion {
  const VerseQuizQuestion({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final Verse prompt;
  final Verse answer;
  final List<Verse> options;

  bool isCorrect(Verse choice) => choice.ref == answer.ref;
}

class VerseQuiz {
  /// Generates at most [count] nonrepeating questions.
  ///
  /// The final verse cannot be a prompt because it has no following verse
  /// within the selected surah. For distractors, at least 5 verses are needed.
  static List<VerseQuizQuestion> generate(
    List<Verse> verses, {
    int count = 5,
    Random? random,
  }) {
    if (count <= 0 || verses.length < 5) return const [];
    final rng = random ?? Random();
    final ordered = [...verses]
      ..sort((a, b) => a.number.compareTo(b.number));
    if (ordered.map((v) => v.surah).toSet().length != 1 ||
        ordered.map((v) => v.number).toSet().length != ordered.length) {
      throw ArgumentError('Quiz requires unique verses from one surah');
    }
    final promptIndices = <int>[];
    for (var i = 0; i < ordered.length - 1; i++) {
      if (ordered[i + 1].number == ordered[i].number + 1) {
        promptIndices.add(i);
      }
    }
    promptIndices.shuffle(rng);
    final result = <VerseQuizQuestion>[];
    for (final index in promptIndices.take(count)) {
      final answer = ordered[index + 1];
      final distractors = ordered.where((v) => v.ref != answer.ref).toList()
        ..shuffle(rng);
      final options = <Verse>[answer, ...distractors.take(3)]..shuffle(rng);
      result.add(VerseQuizQuestion(
        prompt: ordered[index],
        answer: answer,
        options: List.unmodifiable(options),
      ));
    }
    return List.unmodifiable(result);
  }
}
