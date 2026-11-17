import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahfidz_quran/services/app_store.dart';
import 'package:tahfidz_quran/services/backup_service.dart';
import 'package:tahfidz_quran/services/review_reminder_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  test('Backup round trip restores memorization, bookmarks and settings', () async {
    await store.set('language', 'en');
    await store.set('reviewNotifications', true);
    await store.changeReviewReminderTime(5, 45);
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 16));
    await store.bookmark('1:1');
    final backup = BackupService.export(
      store, now: DateTime.utc(2026, 11, 16, 8),
    );
    final preview = BackupService.inspect(backup);
    expect(preview.memorized, 1);
    expect(preview.bookmarks, 1);
    expect(preview.createdAt, DateTime.utc(2026, 11, 16, 8));
    await store.mark('1:1', 'none');
    await store.set('language', 'id');
    await BackupService.restore(store, preview);
    expect(store.map('progress')['1:1'], 'done');
    expect(store.map('bookmarks')['1:1'], true);
    expect(store.get('language', ''), 'en');
    expect(store.get('reviewNotifications', false), isTrue);
    expect(store.get<int>('reviewReminderHour', -1), 5);
    expect(store.get<int>('reviewReminderMinute', -1), 45);
    final reloaded = AppStore(store.prefs);
    expect(reloaded.data, preview.data);
    reloaded.dispose();
  });

  test('Malformed, unsupported and altered backups never replace data', () async {
    await store.set('language', 'id');
    final good = BackupService.export(store);
    expect(() => BackupService.inspect('not-json'), throwsFormatException);
    final decoded = jsonDecode(good) as Map<String, dynamic>;
    decoded['version'] = 999;
    expect(
      () => BackupService.inspect(jsonEncode(decoded)),
      throwsFormatException,
    );
    decoded['version'] = 1;
    (decoded['data'] as Map<String, dynamic>)['language'] = 'en';
    expect(
      () => BackupService.inspect(jsonEncode(decoded)),
      throwsFormatException,
    );
    expect(store.get('language', ''), 'id');
  });

  test('Correct checksum does not allow invalid verse data', () {
    final data = {
      'progress': {'999:123': 'done'},
      'goal': 5,
    };
    final text = jsonEncode({
      'format': BackupService.format,
      'version': BackupService.version,
      'createdAt': DateTime.utc(2026, 11, 16).toIso8601String(),
      'data': data,
      'checksum': sha256.convert(utf8.encode(jsonEncode(data))).toString(),
    });
    expect(() => BackupService.inspect(text), throwsFormatException);
  });

  test('Murajaah reminder plan respects due date and local morning', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 16));
    final morning = upcomingReviewReminders(
      store, DateTime(2026, 11, 16, 7),
    );
    expect(morning.first.id, 1001);
    expect(morning.first.when, DateTime(2026, 11, 17, 8));
    expect(morning.first.count, 1);
    final afterMorning = upcomingReviewReminders(
      store, DateTime(2026, 11, 17, 9),
    );
    expect(afterMorning.first.id, 1001);
    expect(afterMorning.first.when, DateTime(2026, 11, 18, 8));
    expect(afterMorning.first.count, 1);
    await store.mark('1:1', 'none', at: DateTime(2026, 11, 17));
    expect(upcomingReviewReminders(
      store, DateTime(2026, 11, 17, 9),
    ), isEmpty);
  });

  test('Custom reminder time is persisted and respects the daily cutoff', () async {
    await store.mark('1:1', 'done', at: DateTime(2026, 11, 16));
    await store.changeReviewReminderTime(5, 45);
    final saved = AppStore(store.prefs);
    expect(ReviewReminderTime.fromStore(saved).label, '05.45');
    saved.dispose();

    final before = upcomingReviewReminders(
      store, DateTime(2026, 11, 17, 5, 30),
    );
    expect(before.first.id, 1000);
    expect(before.first.when, DateTime(2026, 11, 17, 5, 45));
    final after = upcomingReviewReminders(
      store, DateTime(2026, 11, 17, 6),
    );
    expect(after.first.id, 1001);
    expect(after.first.when, DateTime(2026, 11, 18, 5, 45));

    await store.changeReviewReminderTime(20, 15);
    expect(ReviewReminderTime.fromStore(store).label, '20.15');
    final evening = upcomingReviewReminders(
      store, DateTime(2026, 11, 17, 6),
    );
    expect(evening.first.id, 1000);
    expect(evening.first.when, DateTime(2026, 11, 17, 20, 15));
  });

  test('Default 08:00 is retained and invalid reminder times are rejected', () async {
    expect(ReviewReminderTime.fromStore(store).label, '08.00');
    expect(
      () => store.changeReviewReminderTime(24, 0),
      throwsRangeError,
    );
    expect(
      () => store.changeReviewReminderTime(8, 60),
      throwsRangeError,
    );
    expect(ReviewReminderTime.fromStore(store).label, '08.00');
    await store.set('reviewReminderHour', 99);
    expect(ReviewReminderTime.fromStore(store).label, '08.00');
  });

  test('Backup rejects out-of-range custom reminder settings', () async {
    await store.set('reviewReminderHour', 24);
    final badHour = BackupService.export(store);
    expect(() => BackupService.inspect(badHour), throwsFormatException);
    await store.set('reviewReminderHour', 5);
    await store.set('reviewReminderMinute', -1);
    final badMinute = BackupService.export(store);
    expect(() => BackupService.inspect(badMinute), throwsFormatException);
  });
}
