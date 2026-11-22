import 'app_store.dart';

/// A completed Next Verse Quiz attempt, not a recitation-accuracy measure.
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.surah,
    required this.correct,
    required this.total,
    required this.time,
  });

  final String id;
  final int surah;
  final int correct;
  final int total;
  final DateTime time;

  int get percent => (correct * 100 / total).round();

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'correct': correct,
    'total': total,
    'time': time.toIso8601String(),
  };

  static QuizAttempt? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final surah = raw['surah'];
    final correct = raw['correct'];
    final total = raw['total'];
    final date = raw['time'];
    if (id is! String || id.isEmpty || id.length > 128 ||
        surah is! int || surah < 1 || surah > 114 ||
        correct is! int || total is! int || total < 1 || total > 100 ||
        correct < 0 || correct > total || date is! String) {
      return null;
    }
    final time = DateTime.tryParse(date);
    if (time == null) return null;
    return QuizAttempt(
      id: id, surah: surah, correct: correct, total: total, time: time,
    );
  }
}

class QuizHistorySummary {
  const QuizHistorySummary(this.attempts);

  final List<QuizAttempt> attempts;

  int get count => attempts.length;
  int? get bestPercent => attempts.isEmpty
      ? null
      : attempts.map((e) => e.percent).reduce((a, b) => a > b ? a : b);
  int? get latestPercent => attempts.isEmpty ? null : attempts.first.percent;
  int? get averagePercent => attempts.isEmpty
      ? null
      : (attempts.map((e) => e.correct / e.total).reduce((a, b) => a + b) /
              attempts.length * 100)
          .round();
}

extension QuizHistoryStore on AppStore {
  /// Most recent first, stored locally alongside memorization progress.
  List<QuizAttempt> get quizAttempts {
    final raw = data['quizHistory'];
    if (raw is! List) return const [];
    final result = <QuizAttempt>[];
    for (final item in raw) {
      final attempt = QuizAttempt.tryParse(item);
      if (attempt != null) result.add(attempt);
    }
    result.sort((a, b) => b.time.compareTo(a.time));
    return List.unmodifiable(result);
  }

  /// Save only a fully finished quiz. The id prevents duplicate saves
  /// from rapid taps or retries. Keep at most 200 recent attempts.
  Future<void> saveQuizAttempt({
    required String id,
    required int surah,
    required int correct,
    required int total,
    DateTime? at,
  }) {
    final attempt = QuizAttempt(
      id: id, surah: surah, correct: correct, total: total,
      time: at ?? DateTime.now(),
    );
    if (QuizAttempt.tryParse(attempt.toJson()) == null) {
      throw ArgumentError('Invalid quiz attempt');
    }
    return update((next) {
      final history = next['quizHistory'] is List
          ? List<dynamic>.from(next['quizHistory'] as List)
          : <dynamic>[];
      if (history.any((raw) => raw is Map && raw['id'] == id)) return;
      history.insert(0, attempt.toJson());
      if (history.length > 200) history.removeRange(200, history.length);
      next['quizHistory'] = history;
    });
  }
}
