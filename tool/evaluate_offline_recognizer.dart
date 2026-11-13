// Local-only evaluation on a user-supplied, licensed JSONL dataset.
import 'dart:convert';
import 'dart:io';

import 'package:tahfidz_quran/services/offline_recitation/arabic_text.dart';
import 'package:tahfidz_quran/services/offline_recitation/text_metrics.dart';
import 'package:tahfidz_quran/services/offline_recitation/worker.dart';

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: dart run tool/evaluate_offline_recognizer.dart MODEL_DIRECTORY DATASET.jsonl',
    );
  }
  final dataset = File(args[1]).absolute;
  var wordEdits = 0,
      words = 0,
      characterEdits = 0,
      characters = 0,
      total = 0,
      failed = 0;
  for (final line in dataset.readAsLinesSync().where(
    (line) => line.trim().isNotEmpty,
  )) {
    final row = jsonDecode(line) as Map<String, dynamic>;
    if ((row['license'] as String? ?? '').trim().isEmpty) {
      throw ArgumentError(
        'Every sample must record its source/permission in license.',
      );
    }
    final path = File.fromUri(
      dataset.parent.uri.resolve(row['audio'] as String),
    ).path;
    final watch = Stopwatch()..start();
    final result = recognizeWhisper(args[0], path);
    final reference = arabicWords(row['reference'] as String);
    final heard = arabicWords(result.text);
    final expectedCharacters = normalizeArabic(row['reference'] as String)
        .replaceAll(' ', '')
        .runes
        .toList();
    final heardCharacters = normalizeArabic(result.text)
        .replaceAll(' ', '')
        .runes
        .toList();
    if (reference.isEmpty) {
      throw ArgumentError('Reference must contain Arabic words.');
    }
    final we = editDistance(reference, heard),
        ce = editDistance(expectedCharacters, heardCharacters);
    wordEdits += we;
    words += reference.length;
    characterEdits += ce;
    characters += expectedCharacters.length;
    total++;
    if (result.reason != null) failed++;
    stdout.writeln(
      jsonEncode({
        'id': row['id'],
        'wer': we / reference.length,
        'cer': ce / expectedCharacters.length,
        'latencyMs': watch.elapsedMilliseconds,
        'reason': result.reason,
        'status': 'unassessed',
      }),
    );
  }
  stdout.writeln(
    jsonEncode({
      'samples': total,
      'wer': words == 0 ? null : wordEdits / words,
      'cer': characters == 0 ? null : characterEdits / characters,
      'failedAudio': failed,
      'abstentions': total,
      'falsePositiveRate': null,
      'note': 'No calibrated verdicts: false-positive rate is undefined, not zero. No raw audio/transcripts stored.',
    }),
  );
}
