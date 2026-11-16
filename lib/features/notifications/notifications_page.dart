import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/practice_store.dart';
import '../tahfidz/review_page.dart';
import '../prayer/prayer_page.dart';
import '../settings/settings_page.dart';

/// Displays the current prayer reminder setup. This is not a message inbox:
/// Android delivers scheduled reminders through the system notification tray.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    final store = session.store;
    final enabled = store.get<bool>('notifications', false);
    final city = store.get<String>('city', '');
    final reminder = store.get<int>('reminder', 10);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Notifikasi', 'Notifications')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF064735), Color(0xFF087F5B)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC5A064)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 34,
                        color: Color(0xFFF2D9A1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('Pengingat waktu salat', 'Prayer time reminders'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enabled
                            ? context.t(
                                'Pengingat salat sudah diaktifkan.',
                                'Prayer reminders are enabled.',
                              )
                            : context.t(
                                'Pengingat salat belum diaktifkan.',
                                'Prayer reminders are not enabled yet.',
                              ),
                        style: const TextStyle(
                          color: Color(0xFFE6F2EC),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            enabled
                                ? Icons.check_circle_outline_rounded
                                : Icons.notifications_off_outlined,
                            color: colors.primary,
                          ),
                          title: Text(
                            context.t('Status notifikasi', 'Notification status'),
                          ),
                          subtitle: Text(
                            enabled
                                ? context.t('Aktif', 'Enabled')
                                : context.t('Tidak aktif', 'Disabled'),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.location_city_outlined,
                              color: colors.primary),
                          title: Text(context.t('Kota jadwal salat', 'Prayer schedule city')),
                          subtitle: Text(
                            city.isEmpty
                                ? context.t('Belum dipilih', 'Not selected')
                                : session.prayer.cities
                                    .firstWhere(
                                      (entry) => entry['id'] == city,
                                      orElse: () => {'lokasi': city},
                                    )['lokasi']
                                    .toString(),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.alarm_rounded, color: colors.primary),
                          title: Text(context.t('Pengingat sebelum salat', 'Reminder before prayer')),
                          subtitle: Text(
                            '$reminder ${context.t('menit', 'minutes')}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.event_repeat_rounded, color: colors.primary),
                    title: Text(context.t('Pengingat murajaah', 'Review reminders')),
                    subtitle: Text(
                      store.get<bool>('reviewNotifications', false)
                          ? context.t(
                              '${store.dueReviews(DateTime.now()).length} ayat perlu diulang hari ini. Pengingat dijadwalkan sekitar pukul 08.00.',
                              '${store.dueReviews(DateTime.now()).length} verses are due today. Reminders are scheduled around 8 AM.',
                            )
                          : context.t('Belum diaktifkan', 'Not enabled'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const ReviewPage()),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    context.t('Atur notifikasi', 'Manage notifications'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PrayerPage(),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    context.t('Lihat jadwal salat', 'View prayer schedule'),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.t(
                    'Pengingat yang dijadwalkan tampil melalui notifikasi Android, bukan sebagai pesan masuk di aplikasi. Pengingat membutuhkan kota dan izin notifikasi.',
                    'Scheduled reminders appear as Android system notifications, not messages inside this app. A city and notification permission are required.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
