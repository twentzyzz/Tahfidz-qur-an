import 'app_store.dart';
import 'practice_store.dart';

/// Read-only dashboard aggregates. Historical activity is never interpreted
/// as proof that a verse is currently memorized.
class MemorizationStats {
  MemorizationStats(this.store, {DateTime? now})
    : today = DateTime(
        (now ?? DateTime.now()).year,
        (now ?? DateTime.now()).month,
        (now ?? DateTime.now()).day,
      );

  final AppStore store;
  final DateTime today;

  int get memorized => store.map('progress').values.where((s) => s == 'done').length;
  int get learning => store.map('progress').values.where((s) => s == 'learning').length;
  int get due => store.dueReviews(today).length;

  /// Old records are deduplicated by verse reference in PracticeStore.
  int activityOn(DateTime date) {
    final raw = store.dailyRecord(date)['refs'];
    if (raw is! List) return 0;
    return raw.whereType<String>().toSet().length;
  }

  /// Oldest to newest, ending today. These counts reflect marking activity,
  /// not a current memorization total.
  List<int> lastSevenDays() => List.generate(
    7,
    (i) => activityOn(DateTime(today.year, today.month, today.day - 6 + i)),
  );

  int get activeDaysLastSeven =>
      lastSevenDays().where((n) => n > 0).length;

  /// Consecutive active calendar days; when today has no activity the streak
  /// may continue from yesterday.
  int get streak {
    var cursor = today;
    if (activityOn(cursor) == 0) {
      cursor = DateTime(today.year, today.month, today.day - 1);
    }
    var days = 0;
    while (days < 36600 && activityOn(cursor) > 0) {
      days++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return days;
  }

  /// Manual ratings are self-reported assessments, not automatically measured
  /// recitation accuracy or AI-verified mistakes.
  Map<String, int> get practiceRatings {
    final counts = {'again': 0, 'help': 0, 'fluent': 0};
    for (final raw in store.data['practiceSessions'] as List? ?? []) {
      if (raw is! Map || raw['ratings'] is! Map) continue;
      for (final rating in (raw['ratings'] as Map).values) {
        if (counts.containsKey(rating)) counts[rating as String] = counts[rating]! + 1;
      }
    }
    return counts;
  }

  /// Verses most often rated 'again' during manual practice.
  List<MapEntry<String, int>> get needsPractice {
    final counts = <String, int>{};
    for (final raw in store.data['practiceSessions'] as List? ?? []) {
      if (raw is! Map || raw['ratings'] is! Map) continue;
      for (final entry in (raw['ratings'] as Map).entries) {
        if (entry.key is String && entry.value == 'again') {
          counts[entry.key as String] = (counts[entry.key as String] ?? 0) + 1;
        }
      }
    }
    final result = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return result.take(5).toList();
  }
}
