import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/home_page.dart';

class TahfidzApp extends StatelessWidget {
  const TahfidzApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tahfidz Quran',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const HomePage(),
  );
}
