import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common.dart';
import '../../services/prayer_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;
  Future<void> chooseCity([String query = '']) async {
    final s = Session.of(context);
    final chosen = await showSearch<String>(
      context: context,
      delegate: CitySearch(
        s.prayer.cities,
        context.t('Cari kota/kabupaten', 'Search city/regency'),
      ),
      query: query,
    );
    if (chosen != null && chosen.isNotEmpty && mounted) {
      await perform(context, () async {
        await s.store.set('city', chosen);
        await s.prayer.schedule();
      });
    }
  }

  Future<void> gps() async {
    setState(() => busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('GPS off');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Permission denied');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final places = await Geocoding(locale: const Locale('id'))
          .placemarkFromCoordinates(p.latitude, p.longitude);
      final name =
          places.first.subAdministrativeArea ?? places.first.locality ?? '';
      await chooseCity(
        name
            .replaceAll(
              RegExp(r'Kabupaten |Kota |Regency|City', caseSensitive: false),
              '',
            )
            .trim(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                'GPS tidak tersedia atau izin ditolak. Pilih kota secara manual.',
                'GPS unavailable or permission denied. Choose a city manually.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final s = Session.of(c);
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Pengaturan', 'Settings'))),
      body: padded([
        DropdownButtonFormField<String>(
          initialValue: s.store.get('language', 'id'),
          decoration: InputDecoration(labelText: c.t('Bahasa', 'Language')),
          items: const [
            DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) => perform(c, () async {
            await s.store.set('language', v);
            await s.prayer.schedule();
          }),
        ),
        SwitchListTile(
          title: Text(c.t('Tema gelap', 'Dark theme')),
          value: s.store.get('dark', false),
          onChanged: (v) => perform(c, () => s.store.set('dark', v)),
        ),
        Text(c.t('Ukuran teks Arab', 'Arabic text size')),
        Slider(
          value: s.store.get<num>('arabicSize', 32).toDouble(),
          min: 24,
          max: 56,
          divisions: 16,
          label: '${s.store.get<num>('arabicSize', 32)}',
          onChanged: (v) => perform(c, () => s.store.set('arabicSize', v)),
        ),
        Text(c.t('Ukuran terjemahan', 'Translation size')),
        Slider(
          value: s.store.get<num>('translationSize', 18).toDouble(),
          min: 14,
          max: 30,
          divisions: 8,
          onChanged: (v) => perform(c, () => s.store.set('translationSize', v)),
        ),
        ListTile(
          title: Text(c.t('Kota/kabupaten', 'City/regency')),
          subtitle: Text(
            s.store.get('city', '').isEmpty
                ? c.t('Belum dipilih', 'Not selected')
                : '${s.prayer.cities.firstWhere((e) => e['id'] == s.store.get('city', ''))['lokasi']} • ${cityZone(s.store.get('city', ''))}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: chooseCity,
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : gps,
          icon: const Icon(Icons.my_location),
          label: Text(c.t('Deteksi lokasi GPS', 'Detect GPS location')),
        ),
        if (busy) const LinearProgressIndicator(),
        SwitchListTile(
          title: Text(c.t('Notifikasi salat', 'Prayer notifications')),
          value: s.store.get('notifications', false),
          onChanged: busy
              ? null
              : (v) async {
                  setState(() => busy = true);
                  await perform(c, () async {
                    if (v && s.store.get('city', '').isEmpty) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(
                            c.t(
                              'Pilih kota terlebih dahulu.',
                              'Choose a city first.',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    if (v && !await s.prayer.enablePermission()) {
                      throw StateError('Notifications denied');
                    }
                    await s.store.set('notifications', v);
                    await s.prayer.schedule();
                  });
                  if (mounted) setState(() => busy = false);
                },
        ),
        DropdownButtonFormField<int>(
          initialValue: s.store.get('reminder', 10),
          decoration: InputDecoration(
            labelText: c.t('Pengingat sebelumnya', 'Advance reminder'),
          ),
          items: [5, 10, 15]
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text('$n ${c.t('menit', 'minutes')}'),
                ),
              )
              .toList(),
          onChanged: (v) => perform(c, () async {
            await s.store.set('reminder', v);
            await s.prayer.schedule();
          }),
        ),
        const SizedBox(height: 16),
        Text(
          c.t(
            'Notifikasi dijadwalkan untuk 7 hari dan diperbarui ketika aplikasi dibuka. Android dapat menunda notifikasi untuk menghemat baterai. Pilih kota sebelum mengaktifkannya.',
            'Notifications are scheduled for 7 days and refreshed when the app opens. Android may delay notifications to save battery. Select a city before enabling them.',
          ),
        ),
        const Divider(),
        Text(
          c.t('Tentang aplikasi', 'About'),
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const Text('Tahfidz Quran • 1.1.0 (2)'),
        Text(c.t('Pengembang: twentzyzz', 'Developer: twentzyzz')),
        const Text(
          'Quran & audio: EQuran.id\nJuz: AlQuran Cloud\nJadwal salat / Prayer times: MyQuran API',
        ),
        Text(
          c.t(
            'Enam qari tersedia. Terjemahan Al-Qur’an tetap bahasa Indonesia dari sumbernya.',
            'Six reciters available. Quran translation remains Indonesian from its source.',
          ),
        ),
      ]),
    );
  }
}

class CitySearch extends SearchDelegate<String> {
  CitySearch(this.cities, String label) : super(searchFieldLabel: label);
  final List<Map<String, dynamic>> cities;
  @override
  List<Widget> buildActions(BuildContext c) => [
    IconButton(
      tooltip: c.t('Hapus pencarian', 'Clear search'),
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];
  @override
  Widget buildLeading(BuildContext c) => IconButton(
    tooltip: c.t('Kembali', 'Back'),
    onPressed: () => close(c, ''),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildSuggestions(BuildContext c) => buildResults(c);
  @override
  Widget buildResults(BuildContext c) {
    final results = cities
        .where(
          (e) => (e['lokasi'] as String).toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(results[i]['lokasi'] as String),
        subtitle: Text(cityZone(results[i]['id'] as String)),
        onTap: () => close(c, results[i]['id'] as String),
      ),
    );
  }
}
