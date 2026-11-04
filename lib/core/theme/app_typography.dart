import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const arabic = TextStyle(fontFamily: 'Amiri', fontSize: 32, height: 2);
  static TextTheme apply(TextTheme base) => base
      .apply(fontFamily: 'Inter')
      .copyWith(
        headlineSmall: base.headlineSmall?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Inter', height: 1.5),
        bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Inter', height: 1.5),
      );
}
