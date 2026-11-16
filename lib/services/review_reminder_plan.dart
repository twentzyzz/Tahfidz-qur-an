import 'app_store.dart';
import 'practice_store.dart';

class ReviewReminder {
  const ReviewReminder(this.id, this.when, this.count);
  final int id;
  final DateTime when;
  final int count;
}

/// Build reminders at 08:00 device-local time for the next seven calendar days.
/// The count is cumulative: overdue verses stay in the reminder until reviewed.
List<ReviewReminder> upcomingReviewReminders(AppStore store, DateTime now) {
  final reminders = <ReviewReminder>[];
  for (var day = 0; day < 7; day++) {
    final when = DateTime(now.year, now.month, now.day + day, 8);
    if (!when.isAfter(now)) continue;
    final due = store.dueReviews(when).length;
    if (due == 0) continue;
    reminders.add(ReviewReminder(1000 + day, when, due));
  }
  return reminders;
}
