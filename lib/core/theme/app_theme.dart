import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF7EDAB4) : AppColors.emerald,
          onPrimary: isDark ? AppColors.darkEmerald : Colors.white,
          primaryContainer: isDark
              ? AppColors.darkEmerald
              : AppColors.softEmerald,
          onPrimaryContainer: isDark
              ? AppColors.softEmerald
              : AppColors.darkEmerald,
          secondary: AppColors.gold,
          surface: isDark ? const Color(0xFF14251F) : AppColors.surface,
          onSurface: isDark ? const Color(0xFFE2EDE5) : AppColors.text,
          onSurfaceVariant: isDark
              ? const Color(0xFFB2C2B8)
              : AppColors.secondaryText,
          outlineVariant: isDark
              ? const Color(0xFF334B40)
              : const Color(0xFFDFE7E0),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      textTheme: AppTypography.apply(base.textTheme),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0D1C16)
          : AppColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0D1C16) : AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: border,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    );
  }
}
