import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/prayer_service.dart';
import '../../widgets/common.dart';
import '../settings/settings_page.dart';

class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(c.t('Ibadah 5 Waktu', 'Daily prayers'))),
    body: const PrayerSummary(full: true),
  );
}

class PrayerSummary extends StatefulWidget {
  const PrayerSummary({super.key, this.full = false});
  final bool full;
  @override
  State<PrayerSummary> createState() => _PrayerSummaryState();
}

class _PrayerSummaryState extends State<PrayerSummary> {
  String loaded = '';
  Future<List<PrayerDay>>? future;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<List<PrayerDay>> load(String city, DateTime now) async {
    final p = Session.of(context).prayer;
    final today = await p.day(city, now);
    try {
      return [
        today,
        await p.day(city, DateTime(now.year, now.month, now.day + 1)),
      ];
    } catch (_) {
      return [today];
    }
  }

  @override
  Widget build(BuildContext c) {
    final s = Session.of(c), city = Session.of(c).store.get('city', '');
    if (city.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            c,
            MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
          ),
          child: Text(
            c.t(
              'Pilih kota untuk jadwal salat',
              'Choose a city for prayer times',
            ),
          ),
        ),
      );
    }
    final now = tz.TZDateTime.now(tz.getLocation(cityZone(city))),
        key =
            '$city:${dateKey(tz.TZDateTime.now(tz.getLocation(cityZone(city))))}';
    if (loaded != key) {
      loaded = key;
      future = load(city, now);
    }
    return FutureBuilder<List<PrayerDay>>(
      future: future,
      builder: (c, snapshot) {
        if (snapshot.hasError) {
          return failure(c, () => setState(() => future = load(city, now)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final days = snapshot.data!, day = days.first;
        String? next;
        tz.TZDateTime? at;
        for (final d in days) {
          for (final k in prayerKeys) {
            if (d.time(k).isAfter(now)) {
              next = k;
              at = d.time(k);
              break;
            }
          }
          if (next != null) break;
        }
        final idx = next == null ? 0 : prayerKeys.indexOf(next);
        final remaining = at?.difference(now),
            cityName = s.prayer.cities.firstWhere(
              (e) => e['id'] == city,
            )['lokasi'];
        final children = <Widget>[
          Text(
            '$cityName • ${cityZone(city).split('/').last}',
            style: Theme.of(c).textTheme.titleMedium,
          ),
          Text(day.date),
          if (next != null)
            Text(
              '${c.t('Salat berikutnya', 'Next prayer')}: ${c.t(prayerId[idx], prayerEn[idx])} • ${remaining!.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          if (days.any((d) => d.cached))
            Text(
              c.t(
                'Jadwal cache offline; belum diperbarui dari server.',
                'Offline cached schedule; not refreshed from server.',
              ),
            ),
          if (!widget.full)
            TextButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute<void>(builder: (_) => const PrayerPage()),
              ),
              child: Text(c.t('Ibadah 5 Waktu', 'Daily prayers')),
            ),
          if (widget.full) ...[
            for (var i = 0; i < 5; i++)
              CheckboxListTile(
                title: Text(c.t(prayerId[i], prayerEn[i])),
                subtitle: Text(day.times[prayerKeys[i]]!),
                value:
                    (s.store.map('prayers')[day.date]
                        as Map?)?[prayerKeys[i]] ==
                    true,
                onChanged: (v) => perform(
                  c,
                  () => s.store.checkPrayer(day.date, prayerKeys[i], v!),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              c.t('Riwayat ibadah', 'Prayer history'),
              style: Theme.of(c).textTheme.titleLarge,
            ),
            for (final date
                in (s.store.map('prayers').keys.toList()..sort()).reversed)
              ListTile(
                title: Text(date),
                trailing: Text(
                  '${(s.store.map('prayers')[date] as Map).values.where((v) => v == true).length} / 5',
                ),
              ),
          ],
        ];
        return widget.full
            ? padded(children)
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              );
      },
    );
  }
}
