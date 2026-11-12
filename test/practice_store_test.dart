import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/practice_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  test(
    'Legacy progress, bookmarks and settings survive additive practice data',
    () async {
      final legacy = {
        'goal': 5,
        'language': 'en',
        'bookmarks': {'2:255': true},
        'progress': {'1:1': 'done', '1:2': 'learning'},
        'history': [
          {'ref': '1:1', 'status': 'done', 'time': '2026-11-01T10:00:00'},
          {'ref': '1:1', 'status': 'done', 'time': '2026-11-01T11:00:00'},
        ],
      };
      await store.prefs.setString('user.v2', jsonEncode(legacy));
      final restored = AppStore(store.prefs);
      expect(restored.dailyRecord(DateTime(2026, 11, 1))['refs'], ['1:1']);
      expect(restored.dailyTarget(DateTime(2026, 11, 1)), isNull);
      expect(restored.dueReviews(DateTime(2026, 11, 2)), ['1:1']);
      await restored.changeDailyGoal(3, at: DateTime(2026, 11, 2));
      final reload = AppStore(store.prefs);
      for (final key in ['language', 'bookmarks', 'progress', 'history']) {
        expect(reload.data[key], legacy[key]);
      }
      restored.dispose();
      reload.dispose();
    },
  );

  test(
    'Calendar deduplicates and keeps achievement after reset and goal changes',
    () async {
      final day = DateTime(2026, 11, 1);
      await store.changeDailyGoal(1, at: day);
      await store.mark('1:1', 'done', at: day);
      await store.mark('1:1', 'done', at: day);
      await store.mark('1:1', 'none', at: DateTime(2026, 11, 2));
      await store.changeDailyGoal(10, at: DateTime(2026, 11, 3));
      expect(store.dailyRecord(day)['refs'], ['1:1']);
      expect(store.dailyTarget(day), 1);
      expect(store.dailyTarget(DateTime(2026, 11, 2)), 1);
      expect(store.dailyTarget(DateTime(2026, 11, 4)), 10);
      expect(store.map('progress'), isEmpty);
      expect(store.dueReviews(DateTime(2026, 11, 4)), isEmpty);
    },
  );

  test('Review intervals cross month/year boundaries; duplicate saves are idempotent', () async {
    final day = DateTime(2026, 12, 31, 23, 50);
    await store.mark('1:1', 'done', at: day);
    expect(store.dueReviews(day), isEmpty);
    expect(store.dueReviews(DateTime(2027, 1, 1)), ['1:1']);
    for (final rating in reviewIntervals.keys) {
      await store.savePractice(
        id: rating,
        mode: 'review',
        ratings: {'1:1': rating},
        at: day,
      );
      final expected = practiceDate(
        DateTime(2026, 12, 31 + reviewIntervals[rating]!),
      );
      expect(store.map('reviews')['1:1']['due'], expected);
    }
    await store.savePractice(
      id: 'fluent',
      mode: 'review',
      ratings: {'1:1': 'again'},
      at: day,
    );
    expect(store.data['practiceSessions'], hasLength(3));
    expect(store.map('reviews')['1:1']['due'], '2027-01-07');
    final restored = AppStore(store.prefs);
    expect(restored.data['practiceSessions'], store.data['practiceSessions']);
    expect(restored.dueReviews(DateTime(2027, 1, 7)), ['1:1']);
    restored.dispose();
  });

  test('Concurrent writes retain every mark and bookmark', () async {
    await Future.wait([
      store.mark('1:1', 'done'),
      store.mark('1:2', 'done'),
      store.bookmark('1:1'),
      store.bookmark('1:2'),
    ]);
    expect(store.map('progress'), {'1:1': 'done', '1:2': 'done'});
    expect(store.map('bookmarks'), {'1:1': true, '1:2': true});
    expect(store.data['history'], hasLength(2));
  });

  test('Exam results never automatically mark a verse as memorized', () async {
    await store.savePractice(
      id: 'exam',
      mode: 'hidden',
      ratings: {'1:1': 'fluent'},
    );
    expect(store.map('progress'), isEmpty);
    expect(store.map('reviews'), isEmpty);
    expect(store.data['practiceSessions'], hasLength(1));
    expect(
      () => store.savePractice(
        id: 'bad',
        mode: 'hidden',
        ratings: {'1:1': 'fake'},
      ),
      throwsArgumentError,
    );
  });
  test('A failed write leaves visible state intact and does not block later writes', () async {
    await store.set('language', 'id');
    await expectLater(
      store.set('unsupported', Object()),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    expect(store.data.containsKey('unsupported'), isFalse);
    await store.set('language', 'en');
    expect(store.get('language', ''), 'en');
    final restored = AppStore(store.prefs);
    expect(restored.get('language', ''), 'en');
    restored.dispose();
  });
}
