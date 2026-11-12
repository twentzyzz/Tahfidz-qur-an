import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../l10n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../services/app_store.dart';
import '../services/practice_store.dart';
import '../services/quran_repository.dart';
import '../services/player_controller.dart';
import '../services/prayer_service.dart';
import '../features/home/home_page.dart';
import 'session.dart';

class TahfidzApp extends StatefulWidget {
  const TahfidzApp({super.key});
  @override
  State<TahfidzApp> createState() => _TahfidzAppState();
}

class _TahfidzAppState extends State<TahfidzApp> {
  AppStore? store;
  final quran = QuranRepository();
  PlayerController? player;
  PrayerService? prayer;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    LicenseRegistry.addLicense(() async* {
      for (final name in ['Amiri', 'Inter']) {
        yield LicenseEntryWithLineBreaks([
          name,
        ], await rootBundle.loadString('assets/fonts/$name-OFL.txt'));
      }
    });
    load();
  }

  Future<void> load() async {
    setState(() => failed = false);
    try {
      tzdata.initializeTimeZones();
      final s = AppStore(await SharedPreferences.getInstance());
      if (s.map('goalHistory').isEmpty) {
        await s.changeDailyGoal(s.get<int>('goal', 5));
      }
      await quran.initialize();
      final p = PrayerService(s);
      await p.initialize();
      if (!mounted) return;
      setState(() {
        store = s;
        prayer = p;
        player = PlayerController();
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    player?.dispose();
    store?.dispose();
    prayer?.client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: failed
                ? FilledButton(
                    onPressed: load,
                    child: const Text('Coba lagi / Retry'),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: store!,
      builder: (context, _) => Session(
        store: store!,
        quran: quran,
        player: player!,
        prayer: prayer!,
        child: MaterialApp(
          title: 'Tahfidz Quran',
          debugShowCheckedModeBanner: false,
          locale: Locale(store!.get('language', 'id')),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: store!.get('dark', false)
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const HomePage(),
        ),
      ),
    );
  }
}
