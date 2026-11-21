import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';
import 'package:tahfidz_quran/services/verse_quiz.dart';

void main() {
  List<Verse> sample(int count, {int surah = 1}) => List.generate(
    count,
    (i) => Verse(surah, i + 1, 'Arabic ${i + 1}', 'Translation ${i + 1}', {}),
  );

  test('questions use the actual following verse with four distinct options', () {
    final questions = VerseQuiz.generate(sample(7), random: Random(42));
    expect(questions, hasLength(5));
    expect(questions.map((q) => q.prompt.ref).toSet(), hasLength(5));
    for (final q in questions) {
      expect(q.answer.number, q.prompt.number + 1);
      expect(q.options, hasLength(4));
      expect(q.options.map((v) => v.ref).toSet(), hasLength(4));
      expect(q.options.any((v) => q.isCorrect(v)), isTrue);
      expect(q.options.where(q.isCorrect), hasLength(1));
    }
  });

  test('last verse is never used as a prompt', () {
    final questions = VerseQuiz.generate(sample(5), count: 10, random: Random(9));
    expect(questions, hasLength(4));
    expect(questions.any((q) => q.prompt.number == 5), isFalse);
  });

  test('short surahs and nonpositive question counts cannot start a quiz', () {
    expect(VerseQuiz.generate(sample(3)), isEmpty);
    expect(VerseQuiz.generate(sample(7), count: 0), isEmpty);
  });

  test('rejects duplicate verses and mixed surah input', () {
    final duplicate = [...sample(5), sample(5).first];
    expect(() => VerseQuiz.generate(duplicate), throwsArgumentError);
    final mixed = [...sample(5), sample(1, surah: 2).first];
    expect(() => VerseQuiz.generate(mixed), throwsArgumentError);
  });

  test('correctness is based on exact surah and verse reference', () {
    final q = VerseQuiz.generate(sample(6), count: 1, random: Random(1)).single;
    expect(q.isCorrect(q.answer), isTrue);
    expect(q.isCorrect(Verse(2, q.answer.number, '', '', {})), isFalse);
  });

  test('a missing consecutive verse is never treated as the next ayah', () {
    final sampleWithGap = sample(7)..removeAt(2);
    final questions = VerseQuiz.generate(sampleWithGap, count: 10, random: Random(1));
    expect(questions.any((q) => q.prompt.number == 2), isFalse);
    expect(questions.every((q) => q.answer.number == q.prompt.number + 1), isTrue);
  });
}
