import 'arabic_text.dart';
export 'arabic_text.dart';
import 'recognition.dart';
export 'recognition.dart';
import '../quran_repository.dart';

enum RecitationStatus { detectedMatch, needsReview, unassessed }

class ReferenceWord {
  const ReferenceWord(this.ref, this.index, this.original, this.normalized);
  final String ref, original, normalized;
  final int index;
}

class WordDifference {
  const WordDifference(this.kind, this.reference, this.heard);
  final String kind, heard;
  final ReferenceWord? reference;
}

class AlignmentResult {
  const AlignmentResult(this.status, this.reason, this.differences);
  final RecitationStatus status;
  final String reason;
  final List<WordDifference> differences;
}

List<ReferenceWord> referenceWords(List<Verse> verses) {
  final result = <ReferenceWord>[];
  for (final verse in verses) {
    var index = 0;
    for (final original in verse.arabic.split(RegExp(r'\s+'))) {
      final normalized = normalizeArabic(original);
      if (normalized.isNotEmpty) {
        result.add(ReferenceWord(verse.ref, ++index, original, normalized));
      }
    }
  }
  return result;
}

AlignmentResult alignRecitation(
  List<Verse> verses,
  RecognitionResult recognition,
) {
  if (recognition.reason != null) {
    return AlignmentResult(
      RecitationStatus.unassessed,
      recognition.reason!,
      const [],
    );
  }
  final expected = referenceWords(verses);
  final heard = arabicWords(recognition.text);
  if (expected.isEmpty ||
      heard.isEmpty ||
      expected.length > 400 ||
      heard.length > 400) {
    return const AlignmentResult(
      RecitationStatus.unassessed,
      'emptyOrTooLong',
      [],
    );
  }
  final costs = List.generate(
    expected.length + 1,
    (i) => List.generate(
      heard.length + 1,
      (j) => i == 0
          ? j
          : j == 0
          ? i
          : 0,
    ),
  );
  for (var i = 1; i <= expected.length; i++) {
    for (var j = 1; j <= heard.length; j++) {
      final substitution =
          costs[i - 1][j - 1] +
          (expected[i - 1].normalized == heard[j - 1] ? 0 : 1);
      final choices = [substitution, costs[i - 1][j] + 1, costs[i][j - 1] + 1]
        ..sort();
      costs[i][j] = choices.first;
    }
  }
  final differences = <WordDifference>[];
  var i = expected.length, j = heard.length;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && expected[i - 1].normalized == heard[j - 1]) {
      i--;
      j--;
    } else if (i > 0 && j > 0 && costs[i][j] == costs[i - 1][j - 1] + 1) {
      differences.add(WordDifference('different', expected[--i], heard[--j]));
    } else if (i > 0 && costs[i][j] == costs[i - 1][j] + 1) {
      differences.add(WordDifference('missing', expected[--i], ''));
    } else {
      differences.add(
        WordDifference(
          'extra',
          i > 0 ? expected[i - 1] : expected.first,
          heard[--j],
        ),
      );
    }
  }
  // A lexical match is not evidence that the ASR or the recitation is correct.
  if (!recognition.qualityValidated) {
    return const AlignmentResult(
      RecitationStatus.unassessed,
      'qualityNotValidated',
      [],
    );
  }
  return AlignmentResult(
    differences.isEmpty
        ? RecitationStatus.detectedMatch
        : RecitationStatus.needsReview,
    'lexicalOnly',
    differences.reversed.toList(),
  );
}

abstract interface class OfflineRecitationRecognizer {
  Future<RecognitionResult> recognize(String wavPath);
}

abstract interface class RecitationDevice
    implements OfflineRecitationRecognizer {
  bool get supported;
  Future<void> prepare();
  Future<void> startRecording();
  Future<String?> stopRecording();
  Future<void> playRecording(String path);
  Future<void> stopPlayback();
  Future<void> removeRecording(String path);
  Future<void> dispose();
}

class RecitationFailure implements Exception {
  const RecitationFailure(this.code);
  final String code;
}
