import 'dart:math';

import 'app_store.dart';
import 'quran_repository.dart';

/// Self-reported recall, not an automated assessment of Quran recitation.
class FlashcardRating {
  const FlashcardRating({
    required this.again,
    required this.remembered,
    required this.last,
  });

  final int again;
  final int remembered;
  final DateTime last;

  int get difficulty => again - remembered;

  Map<String, dynamic> toJson() => {
    'again': again,
    'remembered': remembered,
    'last': last.toIso8601String(),
  };

  static FlashcardRating? tryParse(Object? raw) {
    if (raw is! Map ||
        raw['again'] is! int ||
        raw['remembered'] is! int ||
        raw['last'] is! String) {
      return null;
    }
    final again = raw['again'] as int;
    final remembered = raw['remembered'] as int;
    final date = DateTime.tryParse(raw['last'] as String);
    if (date == null || again < 0 || remembered < 0 ||
        again > 1000000 || remembered > 1000000) return null;
    return FlashcardRating(again: again, remembered: remembered, last: date);
  }
}

class FlashcardDeck {
  /// Put the cards that were marked "Again" more often earlier.
  /// Randomize ties so successive practice sessions are not identical.
  static List<Verse> generate(
    List<Verse> verses,
    Map<String, FlashcardRating> ratings, {
    int limit = 10,
    Random? random,
  }) {
    if (limit <= 0 || verses.isEmpty) return const [];
    final seen = <String>{};
    final cards = verses.where((verse) => seen.add(verse.ref)).toList()
      ..shuffle(random ?? Random());
    cards.sort((a, b) {
      final aScore = ratings[a.ref]?.difficulty ?? 0;
      final bScore = ratings[b.ref]?.difficulty ?? 0;
      return bScore.compareTo(aScore);
    });
    return List.unmodifiable(cards.take(limit));
  }
}

/// A difficult card returns once more at the end of the current session.
/// Keeping a fixed retry limit prevents an endless flashcard session.
class FlashcardSession {
  FlashcardSession(List<Verse> cards) : _cards = List.of(cards);

  final List<Verse> _cards;
  final Set<String> _retried = {};
  int _position = 0;
  int _remembered = 0;
  int _again = 0;

  Verse? get current => isFinished ? null : _cards[_position];
  bool get isFinished => _position >= _cards.length;
  int get completed => _position;
  int get total => _cards.length;
  int get remembered => _remembered;
  int get again => _again;

  void rate({required bool remembered}) {
    final verse = current;
    if (verse == null) throw StateError('Flashcard session is finished');
    if (remembered) {
      _remembered++;
    } else {
      _again++;
      if (_retried.add(verse.ref)) _cards.add(verse);
    }
    _position++;
  }
}

extension FlashcardRatingsStore on AppStore {
  Map<String, FlashcardRating> get flashcardRatings {
    final raw = data['flashcardRatings'];
    if (raw is! Map) return const {};
    final result = <String, FlashcardRating>{};
    for (final e in raw.entries) {
      if (e.key is! String || !validFlashcardRef(e.key as String)) continue;
      final rating = FlashcardRating.tryParse(e.value);
      if (rating != null) result[e.key as String] = rating;
    }
    return Map.unmodifiable(result);
  }

  Future<void> rateFlashcard(
    String ref, {
    required bool remembered,
    DateTime? at,
  }) {
    if (!validFlashcardRef(ref)) throw ArgumentError.value(ref, 'ref');
    final now = at ?? DateTime.now();
    return update((next) {
      final raw = Map<String, dynamic>.from(
        next['flashcardRatings'] as Map? ?? {},
      );
      final previous = FlashcardRating.tryParse(raw[ref]);
      raw[ref] = FlashcardRating(
        again: (previous?.again ?? 0) + (remembered ? 0 : 1),
        remembered: (previous?.remembered ?? 0) + (remembered ? 1 : 0),
        last: now,
      ).toJson();
      next['flashcardRatings'] = raw;
    });
  }
}

bool validFlashcardRef(String ref) {
  final match = RegExp(r'^(\d{1,3}):(\d{1,3})$').firstMatch(ref);
  if (match == null) return false;
  final surah = int.parse(match.group(1)!);
  final verse = int.parse(match.group(2)!);
  return surah >= 1 && surah <= 114 && verse >= 1 && verse <= 286;
}
