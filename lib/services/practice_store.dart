import 'app_store.dart';

String practiceDate(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

/// Calendar-day intervals; these are self-assessments, not measured accuracy.
const reviewIntervals = {'again': 1, 'help': 3, 'fluent': 7};

extension PracticeStore on AppStore {
  /// Old history is retained. Its original daily targets are unknown.
  Map<String, dynamic> get dailyRecords {
    final days = <String, dynamic>{};
    for (final raw in data['history'] as List? ?? []) {
      final h = Map<String, dynamic>.from(raw as Map);
      final time = DateTime.tryParse(h['time'] as String? ?? '');
      if (time == null || h['status'] != 'done') continue;
      final key = practiceDate(time);
      final day = days.putIfAbsent(
        key,
        () => <String, dynamic>{'refs': <String>[]},
      ) as Map<String, dynamic>;
      final refs = day['refs'] as List<String>;
      if (!refs.contains(h['ref'])) refs.add(h['ref'] as String);
    }
    days.addAll(map('dailyRecords'));
    return days;
  }

  Map<String, dynamic> dailyRecord(DateTime date) =>
      Map<String, dynamic>.from(dailyRecords[practiceDate(date)] as Map? ?? {});

  int? dailyTarget(DateTime date) {
    final recorded = dailyRecord(date)['goal'] as int?;
    if (recorded != null) return recorded;
    final goals = map('goalHistory');
    final keys =
        goals.keys
            .where((key) => key.compareTo(practiceDate(date)) <= 0)
            .toList()
          ..sort();
    if (keys.isNotEmpty) return goals[keys.last] as int;
    return practiceDate(date) == practiceDate(DateTime.now())
        ? get<int>('goal', 5)
        : null;
  }

  Future<void> changeDailyGoal(int goal, {DateTime? at}) {
    if (![1, 3, 5, 10, 20].contains(goal)) {
      throw ArgumentError.value(goal, 'goal');
    }
    final date = at ?? DateTime.now();
    return update((next) {
      final days = Map<String, dynamic>.from(
        next['dailyRecords'] as Map? ?? {},
      );
      days[practiceDate(date)] = {...dailyRecord(date), 'goal': goal};
      final goals = Map<String, dynamic>.from(
        next['goalHistory'] as Map? ?? {},
      );
      goals[practiceDate(date)] = goal;
      next['goalHistory'] = goals;
      next['goal'] = goal;
      next['dailyRecords'] = days;
    });
  }

  /// An existing memorized verse without a schedule is due immediately.
  List<String> dueReviews(DateTime now) {
    final reviews = map('reviews');
    final today = practiceDate(now);
    final refs = map('progress').entries
        .where((e) => e.value == 'done')
        .map((e) => e.key)
        .where(
          (ref) =>
              ((reviews[ref] as Map?)?['due'] as String? ?? today).compareTo(
                today,
              ) <=
              0,
        )
        .toList();
    refs.sort((a, b) {
      final ad = (reviews[a] as Map?)?['due'] as String? ?? today;
      final bd = (reviews[b] as Map?)?['due'] as String? ?? today;
      return ad == bd ? a.compareTo(b) : ad.compareTo(bd);
    });
    return refs;
  }

  Future<void> savePractice({
    required String id,
    required String mode,
    required Map<String, String> ratings,
    DateTime? at,
  }) {
    if (ratings.isEmpty ||
        ratings.values.any((value) => !reviewIntervals.containsKey(value)) ||
        !['hidden', 'continue', 'review'].contains(mode)) {
      throw ArgumentError('Invalid practice result');
    }
    final now = at ?? DateTime.now();
    return update((next) {
      final sessions = List<dynamic>.from(
        next['practiceSessions'] as List? ?? [],
      );
      if (sessions.any((s) => (s as Map)['id'] == id)) return;
      sessions.insert(0, {
        'id': id,
        'mode': mode,
        'time': now.toIso8601String(),
        'ratings': Map<String, String>.from(ratings),
      });
      final reviews = Map<String, dynamic>.from(next['reviews'] as Map? ?? {});
      final progress = next['progress'] as Map? ?? {};
      for (final entry in ratings.entries) {
        if (progress[entry.key] != 'done') continue;
        final interval = reviewIntervals[entry.value]!;
        reviews[entry.key] = {
          'rating': entry.value,
          'last': now.toIso8601String(),
          'due': practiceDate(
            DateTime(now.year, now.month, now.day + interval),
          ),
        };
      }
      next['practiceSessions'] = sessions;
      next['reviews'] = reviews;
    });
  }
}
