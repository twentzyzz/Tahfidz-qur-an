import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> set(String key, dynamic value) {
    data[key] = value;
    notifyListeners();
    final snapshot = jsonEncode(data);
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (!await prefs.setString('user.v2', snapshot)) {
        throw StateError('Storage write failed');
      }
    });
    return _pending;
  }

  Map<String, dynamic> map(String key) =>
      Map<String, dynamic>.from(data[key] as Map? ?? {});
  Future<void> bookmark(String ref) {
    final m = map('bookmarks');
    if (m.containsKey(ref)) {
      m.remove(ref);
    } else {
      m[ref] = true;
    }
    return set('bookmarks', m);
  }

  Future<void> mark(String ref, String status) async {
    final m = map('progress');
    if (status == 'none') {
      m.remove(ref);
    } else {
      m[ref] = status;
    }
    await set('progress', m);
    final history = List<dynamic>.from(data['history'] as List? ?? []);
    history.insert(0, {
      'ref': ref,
      'status': status,
      'time': DateTime.now().toIso8601String(),
    });
    await set('history', history);
  }

  Future<void> checkPrayer(String date, String prayer, bool checked) {
    final all = map('prayers');
    final day = Map<String, dynamic>.from(all[date] as Map? ?? {});
    day[prayer] = checked;
    all[date] = day;
    return set('prayers', all);
  }
}
