import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../l10n/app_strings.dart';
import '../core/constants/app_colors.dart';
import '../services/app_store.dart';
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
    load();
  }

  Future<void> load() async {
    setState(() => failed = false);
    try {
      tzdata.initializeTimeZones();
      final s = AppStore(await SharedPreferences.getInstance());
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
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          themeMode: store!.get('dark', false)
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const HomePage(),
        ),
      ),
    );
  }

  ThemeData theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: b,
      secondary: AppColors.gold,
    );
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: b,
      scaffoldBackgroundColor: dark ? scheme.surface : AppColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? scheme.surface : AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
