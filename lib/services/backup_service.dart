import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'app_store.dart';
import 'quiz_history_store.dart';

/// Versioned, self-contained backup of the user's local Tahfidz Quran data.
class BackupService {
  static const format = 'tahfidz-quran-backup';
  static const version = 1;
  static const maxBytes = 4 * 1024 * 1024;

  static String export(AppStore store, {DateTime? now}) {
    final data = jsonDecode(jsonEncode(store.data)) as Map<String, dynamic>;
    final checksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'checksum': checksum,
      'data': data,
    });
  }

  static BackupPreview inspect(String text) {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Backup terlalu besar (maksimum 4 MB).');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != format ||
        decoded['version'] != version ||
        decoded['createdAt'] is! String ||
        DateTime.tryParse(decoded['createdAt'] as String) == null ||
        decoded['checksum'] is! String ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('Format atau versi backup tidak didukung.');
    }
    final data = decoded['data'] as Map<String, dynamic>;
    final expected = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    if (decoded['checksum'] != expected) {
      throw const FormatException('Isi backup tidak cocok dengan checksum.');
    }
    _validate(data);
    final progress = data['progress'] as Map? ?? {};
    final bookmarks = data['bookmarks'] as Map? ?? {};
    return BackupPreview(
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      data: Map<String, dynamic>.from(data),
      memorized: progress.values.where((v) => v == 'done').length,
      learning: progress.values.where((v) => v == 'learning').length,
      bookmarks: bookmarks.length,
    );
  }

  static Future<void> restore(AppStore store, BackupPreview backup) =>
      store.update((next) {
        next
          ..clear()
          ..addAll(backup.data);
      });

  static void _validate(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw const FormatException('Backup tidak berisi data pengguna.');
    }
    for (final key in [
      'progress', 'bookmarks', 'reviews', 'dailyRecords',
      'goalHistory', 'last', 'lastMemorization', 'prayers',
    ]) {
      if (data[key] != null && data[key] is! Map) {
        throw FormatException('Data $key tidak valid.');
      }
    }
    for (final key in ['history', 'practiceSessions', 'quizHistory']) {
      if (data[key] != null && data[key] is! List) {
        throw FormatException('Data $key tidak valid.');
      }
    }
    const statuses = {'done', 'learning'};
    final progress = data['progress'] as Map? ?? {};
    for (final e in progress.entries) {
      if (e.key is! String || !_validRef(e.key as String) ||
          !statuses.contains(e.value)) {
        throw const FormatException('Data progres ayat tidak valid.');
      }
    }
    final bookmarks = data['bookmarks'] as Map? ?? {};
    for (final e in bookmarks.entries) {
      if (e.key is! String || !_validRef(e.key as String) ||
          e.value != true) {
        throw const FormatException('Data bookmark tidak valid.');
      }
    }
    final reviews = data['reviews'] as Map? ?? {};
    for (final e in reviews.entries) {
      if (e.key is! String || !_validRef(e.key as String) ||
          e.value is! Map || (e.value as Map)['due'] is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$')
              .hasMatch((e.value as Map)['due'] as String)) {
        throw const FormatException('Jadwal murajaah tidak valid.');
      }
    }
    if (data['goal'] != null &&
        (data['goal'] is! int ||
            ![1, 3, 5, 10, 20].contains(data['goal']))) {
      throw const FormatException('Target harian tidak valid.');
    }
    if (data['dark'] != null && data['dark'] is! bool) {
      throw const FormatException('Tema tidak valid.');
    }
    if (data['notifications'] != null && data['notifications'] is! bool) {
      throw const FormatException('Notifikasi salat tidak valid.');
    }
    if (data['reviewNotifications'] != null &&
        data['reviewNotifications'] is! bool) {
      throw const FormatException('Notifikasi murajaah tidak valid.');
    }
    if (data['reviewReminderHour'] != null &&
        (data['reviewReminderHour'] is! int ||
            (data['reviewReminderHour'] as int) < 0 ||
            (data['reviewReminderHour'] as int) > 23)) {
      throw const FormatException('Jam pengingat murajaah tidak valid.');
    }
    if (data['reviewReminderMinute'] != null &&
        (data['reviewReminderMinute'] is! int ||
            (data['reviewReminderMinute'] as int) < 0 ||
            (data['reviewReminderMinute'] as int) > 59)) {
      throw const FormatException('Menit pengingat murajaah tidak valid.');
    }
    if (data['language'] != null &&
        !['id', 'en'].contains(data['language'])) {
      throw const FormatException('Bahasa tidak valid.');
    }
    // Backup data must never introduce malformed or duplicate quiz attempts.
    final quiz = data['quizHistory'] as List? ?? [];
    if (quiz.length > 200 ||
        quiz.any((item) => QuizAttempt.tryParse(item) == null) ||
        quiz.whereType<Map>().map((e) => e['id']).toSet().length != quiz.length) {
      throw const FormatException('Riwayat nilai kuis tidak valid.');
    }
    final history = data['history'] as List? ?? [];
    if (history.any((e) =>
        e is! Map ||
        e['ref'] is! String ||
        !_validRef(e['ref'] as String) ||
        e['status'] is! String ||
        !{'done', 'learning', 'none'}.contains(e['status']) ||
        e['time'] is! String)) {
      throw const FormatException('Riwayat hafalan tidak valid.');
    }
  }

  static bool _validRef(String ref) {
    final m = RegExp(r'^(\d{1,3}):(\d{1,3})$').firstMatch(ref);
    if (m == null) return false;
    final surah = int.parse(m.group(1)!);
    final ayah = int.parse(m.group(2)!);
    return surah >= 1 && surah <= 114 && ayah >= 1 && ayah <= 286;
  }
}

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.data,
    required this.memorized,
    required this.learning,
    required this.bookmarks,
  });

  final DateTime createdAt;
  final Map<String, dynamic> data;
  final int memorized, learning, bookmarks;
}
