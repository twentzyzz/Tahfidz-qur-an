import 'app_store.dart';
import 'practice_store.dart';

class ReviewReminder {
  const ReviewReminder(this.id, this.when, this.count);
  final int id;
  final DateTime when;
  final int count;
}

/// Local device wall-clock time. Existing installations default to 08:00.
class ReviewReminderTime {
  const ReviewReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  factory ReviewReminderTime.fromStore(AppStore store) {
    final hour = store.get<int>('reviewReminderHour', 8);
    final minute = store.get<int>('reviewReminderMinute', 0);
    return ReviewReminderTime(
      hour >= 0 && hour < 24 ? hour : 8,
      minute >= 0 && minute < 60 ? minute : 0,
    );
  }

  String get label =>
      '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';
}

/// Build reminders at the user's chosen device-local time for seven days.
/// Overdue verses remain due until reviewed; earlier dates are skipped.
List<ReviewReminder> upcomingReviewReminders(AppStore store, DateTime now) {
  final reminders = <ReviewReminder>[];
  final time = ReviewReminderTime.fromStore(store);
  for (var day = 0; day < 7; day++) {
    final when = DateTime(
      now.year,
      now.month,
      now.day + day,
      time.hour,
      time.minute,
    );
    if (!when.isAfter(now)) continue;
    final due = store.dueReviews(when).length;
    if (due == 0) continue;
    reminders.add(ReviewReminder(1000 + day, when, due));
  }
  return reminders;
}
