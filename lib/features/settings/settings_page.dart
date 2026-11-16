import '../qari/qari_page.dart';
import 'backup_page.dart';
import '../../services/player_controller.dart';
import '../../core/constants/app_colors.dart';

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
    final session = Session.of(c);
    final store = session.store;
    final theme = Theme.of(c);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cityId = store.get<String>('city', '');
    final cityName = cityId.isEmpty
        ? c.t('Belum dipilih', 'Not selected')
        : session.prayer.cities
            .firstWhere(
              (entry) => entry['id'] == cityId,
              orElse: () => {'lokasi': cityId},
            )['lokasi']
            .toString();
    final arabicSize = store.get<num>('arabicSize', 32).toDouble();
    final translationSize = store.get<num>('translationSize', 18).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(c.t('Pengaturan', 'Settings'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            key: const PageStorageKey('settings-premium'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF064735),
                      Color(0xFF087759),
                      Color(0xFF0B4B3A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF064735).withValues(alpha: .16),
                      blurRadius: 20,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.goldLight,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.t('PENGALAMAN PERSONAL', 'PERSONAL EXPERIENCE'),
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        c.t('Ibadah yang terasa lebih dekat', 'Make worship feel closer'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.t(
                          'Sesuaikan bacaan Al-Qur’an, pengingat, dan keamanan data hafalanmu.',
                          'Personalize Quran reading, reminders, and memorization data.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFE4F3EB),
                          height: 1.55,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill(
                            icon: Icons.menu_book_rounded,
                            label: c.t('Al-Qur’an', 'Quran'),
                          ),
                          _HeroPill(
                            icon: Icons.notifications_active_outlined,
                            label: c.t('Pengingat', 'Reminders'),
                          ),
                          _HeroPill(
                            icon: Icons.shield_outlined,
                            label: c.t('Data lokal', 'Local data'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SettingsSection(
                icon: Icons.headphones_rounded,
                title: c.t('Audio & bahasa', 'Audio & language'),
                subtitle: c.t(
                  'Atur suara dan kenyamanan membaca.',
                  'Choose your recitation and language.',
                ),
              ),
              _SettingsPanel(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const _SettingIcon(icon: Icons.graphic_eq_rounded),
                    title: Text(
                      c.t('Qari & audio', 'Reciter & audio'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      qaris[store.get<String>('qari', '05')] ?? qaris['05']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.primary,
                    ),
                    onTap: () => Navigator.push(
                      c,
                      MaterialPageRoute<void>(builder: (_) => const QariPage()),
                    ),
                  ),
                  const Divider(height: 22),
                  _SettingFieldTitle(
                    icon: Icons.language_rounded,
                    title: c.t('Bahasa aplikasi', 'App language'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: store.get('language', 'id'),
                    decoration: InputDecoration(
                      labelText: c.t('Bahasa', 'Language'),
                      prefixIcon: const Icon(Icons.translate_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'id',
                        child: Text('Bahasa Indonesia'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (v) => perform(c, () async {
                      await store.set('language', v);
                      await session.prayer.schedule();
                    }),
                  ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _SettingIcon(icon: Icons.dark_mode_outlined),
                    title: Text(
                      c.t('Tema gelap', 'Dark theme'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      c.t('Tampilan nyaman di malam hari', 'A softer look at night'),
                    ),
                    value: store.get('dark', false),
                    onChanged: (v) => perform(c, () => store.set('dark', v)),
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.auto_stories_rounded,
                title: c.t('Tampilan Al-Qur’an', 'Quran appearance'),
                subtitle: c.t(
                  'Ukuran tulisan sesuai kenyamanan mata.',
                  'Set text sizes for comfortable reading.',
                ),
              ),
              _SettingsPanel(
                children: [
                  _SizeHeader(
                    title: c.t('Ukuran teks Arab', 'Arabic text size'),
                    size: arabicSize.round(),
                  ),
                  Slider(
                    value: arabicSize.clamp(24.0, 56.0),
                    min: 24,
                    max: 56,
                    divisions: 16,
                    label: '${arabicSize.round()}',
                    onChanged: (v) => perform(
                      c,
                      () => store.set('arabicSize', v),
                    ),
                  ),
                  const Divider(height: 16),
                  _SizeHeader(
                    title: c.t('Ukuran terjemahan', 'Translation size'),
                    size: translationSize.round(),
                  ),
                  Slider(
                    value: translationSize.clamp(14.0, 30.0),
                    min: 14,
                    max: 30,
                    divisions: 8,
                    label: '${translationSize.round()}',
                    onChanged: (v) => perform(
                      c,
                      () => store.set('translationSize', v),
                    ),
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.mosque_outlined,
                title: c.t('Pengingat ibadah', 'Worship reminders'),
                subtitle: c.t(
                  'Jadwalkan murajaah dan waktu salat.',
                  'Plan your reviews and prayer reminders.',
                ),
              ),
              _SettingsPanel(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _SettingIcon(icon: Icons.event_repeat_rounded),
                    title: Text(
                      c.t('Pengingat murajaah', 'Review reminders'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      c.t(
                        'Pukul 08.00 jika ada ayat yang perlu diulang.',
                        'At 8 AM when memorized verses are due.',
                      ),
                    ),
                    value: store.get<bool>('reviewNotifications', false),
                    onChanged: busy ? null : (enabled) async {
                      setState(() => busy = true);
                      try {
                        if (enabled && !await session.prayer.enablePermission()) {
                          if (c.mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                              content: Text(c.t(
                                'Izin notifikasi diperlukan untuk pengingat murajaah.',
                                'Notification permission is required for review reminders.',
                              )),
                            ));
                          }
                          return;
                        }
                        await store.set('reviewNotifications', enabled);
                      } catch (_) {
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                            content: Text(c.t(
                              'Pengaturan pengingat gagal disimpan.',
                              'Could not save review reminder setting.',
                            )),
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const _SettingIcon(icon: Icons.location_on_outlined),
                    title: Text(
                      c.t('Kota/kabupaten', 'City/regency'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      cityId.isEmpty
                          ? c.t('Pilih kota untuk jadwal salat', 'Choose a city for prayer times')
                          : '$cityName • ${cityZone(cityId)}',
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.primary),
                    onTap: chooseCity,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : gps,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location_rounded, size: 19),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.t('Deteksi lokasi GPS', 'Detect GPS location'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _SettingIcon(icon: Icons.notifications_outlined),
                    title: Text(
                      c.t('Notifikasi salat', 'Prayer notifications'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      c.t(
                        'Pengingat sebelum waktu salat',
                        'Reminders before prayer time',
                      ),
                    ),
                    value: store.get('notifications', false),
                    onChanged: busy ? null : (enabled) async {
                      setState(() => busy = true);
                      await perform(c, () async {
                        if (enabled && store.get('city', '').isEmpty) {
                          ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                            content: Text(c.t(
                              'Pilih kota terlebih dahulu.',
                              'Choose a city first.',
                            )),
                          ));
                          return;
                        }
                        if (enabled && !await session.prayer.enablePermission()) {
                          throw StateError('Notifications denied');
                        }
                        await store.set('notifications', enabled);
                        await session.prayer.schedule();
                      });
                      if (mounted) setState(() => busy = false);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: store.get('reminder', 10),
                    decoration: InputDecoration(
                      labelText: c.t('Pengingat sebelumnya', 'Advance reminder'),
                      prefixIcon: const Icon(Icons.alarm_rounded),
                    ),
                    items: [5, 10, 15]
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(
                                '$n ${c.t('menit', 'minutes')}',
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => perform(c, () async {
                      await store.set('reminder', v);
                      await session.prayer.schedule();
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: isDark ? .12 : .065),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.t(
                              'Notifikasi dijadwalkan untuk 7 hari dan diperbarui saat aplikasi dibuka. Android dapat menundanya untuk menghemat baterai.',
                              'Reminders are scheduled for 7 days and refreshed when the app opens. Android may delay them to save battery.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: .85),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _SettingsSection(
                icon: Icons.cloud_done_outlined,
                title: c.t('Data & backup', 'Data & backup'),
                subtitle: c.t(
                  'Jaga agar progres hafalan tetap tersimpan.',
                  'Keep your memorization progress safe.',
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('settings-backup-link'),
                  onTap: () => Navigator.push(
                    c,
                    MaterialPageRoute<void>(builder: (_) => const BackupPage()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            Icons.settings_backup_restore_rounded,
                            size: 27,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.t(
                                  'Backup & pulihkan hafalan',
                                  'Backup & restore memorization',
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.t(
                                  'Simpan file cadangan progres, bookmark, dan riwayat. Pulihkan kapan saja.',
                                  'Save progress, bookmarks, and history to a backup file. Restore anytime.',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: .82),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 15, color: colors.primary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      c.t('Disimpan secara lokal', 'Stored locally'),
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: colors.primary, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              _SettingsSection(
                icon: Icons.info_outline_rounded,
                title: c.t('Tentang aplikasi', 'About the app'),
                subtitle: c.t(
                  'Informasi versi dan sumber data.',
                  'App version and data credits.',
                ),
              ),
              _SettingsPanel(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.darkEmerald, AppColors.emerald],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 28,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tahfidz Quran',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.t('Teman perjalanan hafalan', 'Your memorization companion'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(label: 'v1.1.0 (2)'),
                      _InfoPill(label: c.t('6 qari', '6 reciters')),
                    ],
                  ),
                  const Divider(height: 30),
                  _AboutLine(
                    label: c.t('Pengembang', 'Developer'),
                    value: 'twentzyzz',
                  ),
                  const SizedBox(height: 10),
                  _AboutLine(
                    label: c.t('Al-Qur’an & audio', 'Quran & audio'),
                    value: 'EQuran.id',
                  ),
                  const SizedBox(height: 10),
                  _AboutLine(label: 'Juz', value: 'AlQuran Cloud'),
                  const SizedBox(height: 10),
                  _AboutLine(
                    label: c.t('Jadwal salat', 'Prayer times'),
                    value: 'MyQuran API',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    c.t(
                      'Enam qari tersedia. Terjemahan Al-Qur’an tetap bahasa Indonesia sesuai sumber.',
                      'Six reciters available. Quran translations remain Indonesian from their source.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: .84),
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => showLicensePage(
                        context: c,
                        applicationName: 'Tahfidz Quran',
                        applicationVersion: '1.1.0 (2)',
                      ),
                      icon: const Icon(Icons.gavel_rounded, size: 20),
                      label: Text(
                        c.t('Lisensi font & pustaka', 'Font & library licenses'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.goldLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 21, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: colors.primary, size: 22),
    );
  }
}

class _SettingFieldTitle extends StatelessWidget {
  const _SettingFieldTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeHeader extends StatelessWidget {
  const _SizeHeader({required this.title, required this.size});
  final String title;
  final int size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            '$size',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
