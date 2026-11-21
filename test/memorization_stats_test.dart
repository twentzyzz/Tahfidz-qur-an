import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/memorization_stats.dart';
import 'package:tahfidz_quran/services/practice_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore store;
  final today = DateTime(2026, 11, 21);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  test('empty records yield zero values and a 7-day zero chart', () {
    final stats = MemorizationStats(store, now: today);
    expect(stats.memorized, 0);
    expect(stats.learning, 0);
    expect(stats.due, 0);
    expect(stats.lastSevenDays(), List.filled(7, 0));
    expect(stats.streak, 0);
    expect(stats.practiceRatings.values.every((n) => n == 0), isTrue);
    expect(stats.needsPractice, isEmpty);
  });

  test('activity deduplicates marks and survives a subsequent reset', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 20));
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 20));
    await store.mark('1:2', 'done', at: today);
    await store.mark('1:1', 'none', at: today);
    await store.mark('1:3', 'learning', at: today);
    final stats = MemorizationStats(store, now: today);
    expect(stats.memorized, 1);
    expect(stats.learning, 1);
    expect(stats.activityOn(DateTime(2026, 11, 20)), 1);
    expect(stats.activityOn(today), 1);
    expect(stats.lastSevenDays().last, 1);
    expect(stats.streak, 2);
    expect(stats.activeDaysLastSeven, 2);
  });

  test('streak continues from yesterday and stops on a gap', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 18));
    await store.mark('1:2', 'done', at: DateTime(2026, 11, 19));
    await store.mark('1:3', 'done', at: DateTime(2026, 11, 20));
    final stats = MemorizationStats(store, now: today);
    expect(stats.streak, 3);
    await store.mark('1:4', 'done', at: today);
    expect(stats.streak, 4);
    final future = MemorizationStats(store, now: DateTime(2026, 11, 23));
    expect(future.streak, 0);
  });

  test('ratings count assessments, not proven recitation errors', () async {
    await store.savePractice(
      id: 'a', mode: 'hidden', at: today,
      ratings: {'1:1': 'again', '1:2': 'help'},
    );
    await store.savePractice(
      id: 'b', mode: 'review', at: today,
      ratings: {'1:1': 'again', '1:3': 'fluent'},
    );
    final stats = MemorizationStats(store, now: today);
    expect(stats.practiceRatings, {'again': 2, 'help': 1, 'fluent': 1});
    expect(stats.needsPractice.first.key, '1:1');
    expect(stats.needsPractice.first.value, 2);
    expect(stats.needsPractice, hasLength(1));
    expect(stats.memorized, 0);
  });

  test('due count only includes currently memorized verses', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 19));
    await store.mark('1:2', 'done', at: today);
    expect(MemorizationStats(store, now: today).due, 1);
    await store.mark('1:1', 'none', at: today);
    expect(MemorizationStats(store, now: today).due, 0);
  });
}
