import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/quiz_history_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  test('new and legacy installs have empty score history', () {
    expect(store.quizAttempts, isEmpty);
    final stats = QuizHistorySummary(store.quizAttempts);
    expect(stats.count, 0);
    expect(stats.bestPercent, isNull);
    expect(stats.averagePercent, isNull);
    expect(stats.latestPercent, isNull);
  });

  test('completed quiz persists with date, surah and score across reload', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 22));
    await store.saveQuizAttempt(
      id: 'attempt-1', surah: 1, correct: 4, total: 5,
      at: DateTime(2026, 11, 23, 9, 30),
    );
    final reloaded = AppStore(await SharedPreferences.getInstance());
    addTearDown(reloaded.dispose);

    expect(reloaded.quizAttempts, hasLength(1));
    final saved = reloaded.quizAttempts.single;
    expect(saved.surah, 1);
    expect(saved.correct, 4);
    expect(saved.total, 5);
    expect(saved.percent, 80);
    expect(saved.time, DateTime(2026, 11, 23, 9, 30));
    expect(reloaded.map('progress')['1:1'], 'done');
  });

  test('duplicate attempt id is ignored, even with conflicting score', () async {
    await store.saveQuizAttempt(id: 'one', surah: 2, correct: 2, total: 5);
    await store.saveQuizAttempt(id: 'one', surah: 2, correct: 5, total: 5);
    expect(store.quizAttempts, hasLength(1));
    expect(store.quizAttempts.single.correct, 2);
  });

  test('invalid scores, surah and ids cannot be saved', () async {
    expect(
      () => store.saveQuizAttempt(id: 'x', surah: 115, correct: 3, total: 5),
      throwsArgumentError,
    );
    expect(
      () => store.saveQuizAttempt(id: 'x', surah: 1, correct: 6, total: 5),
      throwsArgumentError,
    );
    expect(
      () => store.saveQuizAttempt(id: '', surah: 1, correct: 0, total: 5),
      throwsArgumentError,
    );
    expect(
      () => store.saveQuizAttempt(id: 'x', surah: 1, correct: 0, total: 0),
      throwsArgumentError,
    );
    expect(store.quizAttempts, isEmpty);
  });

  test('average, best and latest scores use actual completed results', () async {
    await store.saveQuizAttempt(
      id: 'old', surah: 1, correct: 0, total: 5,
      at: DateTime(2026, 11, 21),
    );
    await store.saveQuizAttempt(
      id: 'middle', surah: 1, correct: 5, total: 5,
      at: DateTime(2026, 11, 22),
    );
    await store.saveQuizAttempt(
      id: 'new', surah: 2, correct: 3, total: 5,
      at: DateTime(2026, 11, 23),
    );
    final summary = QuizHistorySummary(store.quizAttempts);
    expect(summary.count, 3);
    expect(summary.bestPercent, 100);
    expect(summary.latestPercent, 60);
    expect(summary.averagePercent, 53);
    expect(store.quizAttempts.map((a) => a.id), ['new', 'middle', 'old']);
    expect(store.map('progress'), isEmpty);
  });

  test('history retains at most 200 recent attempts', () async {
    for (var i = 0; i < 202; i++) {
      await store.saveQuizAttempt(
        id: 'attempt-$i', surah: 1, correct: i % 6, total: 5,
        at: DateTime(2026, 11, 23, 0, 0, i),
      );
    }
    expect(store.quizAttempts, hasLength(200));
    expect(store.quizAttempts.first.id, 'attempt-201');
    expect(store.quizAttempts.last.id, 'attempt-2');
  });

  test('malformed legacy quiz history entries are safely ignored', () async {
    await store.set('quizHistory', [
      {'id': 'broken', 'surah': 1, 'correct': 7, 'total': 5, 'time': 'bad'},
      'invalid',
    ]);
    expect(store.quizAttempts, isEmpty);
  });
}
