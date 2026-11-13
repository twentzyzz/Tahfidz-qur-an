import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'practice_store.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.prefs) {
    data =
        jsonDecode(prefs.getString('user.v2') ?? '{}') as Map<String, dynamic>;
  }
  final SharedPreferences prefs;
  late Map<String, dynamic> data;
  Future<void> _pending = Future.value();
  T get<T>(String key, T fallback) =>
      data[key] is T ? data[key] as T : fallback;
  Future<void> set(String key, dynamic value) =>
      update((next) => next[key] = value);

  /// Serialize whole-document writes and publish only successfully saved state.
  Future<void> update(void Function(Map<String, dynamic>) change) {
    final operation = _pending.catchError((Object _) {}).then((_) async {
      final next = Map<String, dynamic>.from(data);
      change(next);
      if (!await prefs.setString('user.v2', jsonEncode(next))) {
        throw StateError('Storage write failed');
      }
      data = next;
      notifyListeners();
    });
    _pending = operation;
    return operation;
  }

  Map<String, dynamic> map(String key) =>
      Map<String, dynamic>.from(data[key] as Map? ?? {});
  Future<void> bookmark(String ref) => update((next) {
    final bookmarks = Map<String, dynamic>.from(
      next['bookmarks'] as Map? ?? {},
    );
    if (bookmarks.containsKey(ref)) {
      bookmarks.remove(ref);
    } else {
      bookmarks[ref] = true;
    }
    next['bookmarks'] = bookmarks;
  });

  Future<void> mark(String ref, String status, {DateTime? at}) {
    if (!['none', 'learning', 'done'].contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    final now = at ?? DateTime.now();
    return update((next) {
      final progress = Map<String, dynamic>.from(
        next['progress'] as Map? ?? {},
      );
      final reviews = Map<String, dynamic>.from(next['reviews'] as Map? ?? {});
      if (status == 'none') {
        progress.remove(ref);
      } else {
        progress[ref] = status;
      }
      if (status == 'done') {
        final goals = Map<String, dynamic>.from(
          next['goalHistory'] as Map? ?? {},
        );
        if (goals.isEmpty) goals[practiceDate(now)] = get('goal', 5);
        next['goalHistory'] = goals;
        final days = Map<String, dynamic>.from(
          next['dailyRecords'] as Map? ?? {},
        );
        final day = dailyRecord(now);
        final refs = List<String>.from(day['refs'] as List? ?? []);
        if (!refs.contains(ref)) refs.add(ref);
        days[practiceDate(now)] = {
          ...day,
          'refs': refs,
          'goal': day['goal'] ?? get('goal', 5),
        };
        next['dailyRecords'] = days;
        reviews.putIfAbsent(
          ref,
          () => {
            'due': practiceDate(DateTime(now.year, now.month, now.day + 1)),
          },
        );
      } else {
        reviews.remove(ref);
      }
      next['progress'] = progress;
      next['reviews'] = reviews;
      next['history'] = [
        {'ref': ref, 'status': status, 'time': now.toIso8601String()},
        ...(next['history'] as List? ?? []),
      ];
    });
  }

  Future<void> checkPrayer(String date, String prayer, bool checked) =>
      update((next) {
        final all = Map<String, dynamic>.from(next['prayers'] as Map? ?? {});
        final day = Map<String, dynamic>.from(all[date] as Map? ?? {});
        day[prayer] = checked;
        all[date] = day;
        next['prayers'] = all;
      });
}
