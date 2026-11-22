import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/backup_service.dart';
import 'package:tahfidz_quran/services/flashcard_store.dart';
import 'package:tahfidz_quran/services/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  List<Verse> verses(int count) => List.generate(
    count,
    (i) => Verse(1, i + 1, 'Arab ${i + 1}', 'Arti ${i + 1}', {}),
  );

  test('new installs have no flashcard ratings', () {
    expect(store.flashcardRatings, isEmpty);
    expect(FlashcardDeck.generate(verses(0), {}), isEmpty);
    expect(FlashcardDeck.generate(verses(7), {}, limit: 0), isEmpty);
  });

  test('cards use verified offline verses, limited and nonduplicated', () {
    final data = verses(12);
    final cards = FlashcardDeck.generate(
      [...data, data.first], {}, random: Random(3),
    );
    expect(cards, hasLength(10));
    expect(cards.map((v) => v.ref).toSet(), hasLength(10));
    expect(data.map((v) => v.ref).toSet().containsAll(cards.map((v) => v.ref)), isTrue);
    expect(FlashcardDeck.generate(verses(3), {}), hasLength(3));
  });

  test('difficult cards are prioritized for subsequent sessions', () async {
    await store.rateFlashcard('1:5', remembered: false);
    await store.rateFlashcard('1:5', remembered: false);
    await store.rateFlashcard('1:2', remembered: true);
    final deck = FlashcardDeck.generate(
      verses(12), store.flashcardRatings,
      limit: 4, random: Random(7),
    );
    expect(deck.first.ref, '1:5');
    expect(deck.map((v) => v.ref), isNot(contains('1:2')));
  });

  test('forgotten card returns once, then session always finishes', () {
    final session = FlashcardSession(verses(2));
    expect(session.current!.ref, '1:1');
    session.rate(remembered: false);
    expect(session.total, 3);
    expect(session.current!.ref, '1:2');
    session.rate(remembered: true);
    expect(session.current!.ref, '1:1');
    session.rate(remembered: false);
    expect(session.isFinished, isTrue);
    expect(session.again, 2);
    expect(session.remembered, 1);
    expect(() => session.rate(remembered: true), throwsStateError);
  });

  test('ratings persist without changing memorization progress or quiz history', () async {
    await store.mark('1:1', 'done');
    await store.rateFlashcard(
      '1:2', remembered: false, at: DateTime(2026, 11, 23, 10),
    );
    await store.rateFlashcard(
      '1:2', remembered: true, at: DateTime(2026, 11, 23, 11),
    );

    final restored = AppStore(await SharedPreferences.getInstance());
    addTearDown(restored.dispose);
    expect(restored.flashcardRatings['1:2']!.again, 1);
    expect(restored.flashcardRatings['1:2']!.remembered, 1);
    expect(restored.flashcardRatings['1:2']!.last, DateTime(2026, 11, 23, 11));
    expect(restored.map('progress'), {'1:1': 'done'});
    expect(restored.data['quizHistory'], isNull);
  });

  test('invalid verse refs and corrupted entries are rejected or ignored', () async {
    expect(
      () => store.rateFlashcard('999:0', remembered: false),
      throwsArgumentError,
    );
    expect(
      () => store.rateFlashcard('1:1;DROP', remembered: true),
      throwsArgumentError,
    );
    await store.set('flashcardRatings', {
      '1:1': {'again': -2, 'remembered': 0, 'last': 'invalid'},
      'not-a-ref': {'again': 1, 'remembered': 1, 'last': '2026-11-23'},
    });
    expect(store.flashcardRatings, isEmpty);
  });

  test('validated backup restores flashcard ratings and rejects tampering', () async {
    await store.rateFlashcard('1:2', remembered: false);
    final backup = BackupService.inspect(BackupService.export(store));

    await store.set('flashcardRatings', <String, dynamic>{});
    await BackupService.restore(store, backup);
    expect(store.flashcardRatings['1:2']?.again, 1);

    await store.set('flashcardRatings', {
      '1:2': {'again': -1, 'remembered': 0, 'last': '2026-11-23'},
    });
    expect(
      () => BackupService.inspect(BackupService.export(store)),
      throwsFormatException,
    );
  });
}
