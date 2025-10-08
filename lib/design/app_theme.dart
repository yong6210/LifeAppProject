import 'package:flutter/material.dart';

/// Centralised design tokens inspired by Toss's clean, minimal finance UI.
/// Provides colour palettes, typography and component themes consumed
/// throughout the app to ensure a consistent look & feel.
class AppTheme {
  static const _brandBlue = Color(0xFF1A73E8);
  static const _brandBlueDark = Color(0xFF0B4CAB);
  static const _brandBlueLight = Color(0xFFE3F1FF);

  static const _surfaceElevated = Color(0xFFFFFFFF);
  static const _surfaceBackground = Color(0xFFF7F9FC);
  static const _neutralText = Color(0xFF1A1C1E);
  static const _neutralSubtitle = Color(0xFF67718A);

  static ColorScheme lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: _brandBlue,
    onPrimary: Colors.white,
    primaryContainer: _brandBlueLight,
    onPrimaryContainer: _brandBlueDark,
    secondary: Color(0xFF3A87FF),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD8E8FF),
    onSecondaryContainer: _brandBlueDark,
    tertiary: Color(0xFF00C6AE),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFBDF6EC),
    onTertiaryContainer: Color(0xFF005247),
    error: Color(0xFFEF5353),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDADA),
    onErrorContainer: Color(0xFF690005),
    background: _surfaceBackground,
    onBackground: _neutralText,
    surface: _surfaceElevated,
    onSurface: _neutralText,
    surfaceVariant: Color(0xFFE1E8F5),
    onSurfaceVariant: Color(0xFF455168),
    outline: Color(0xFFCAD4EB),
    shadow: Colors.black12,
    inverseSurface: Color(0xFF2A2E3A),
    onInverseSurface: Colors.white,
    inversePrimary: _brandBlueDark,
    surfaceTint: _brandBlue,
  );

  static ThemeData lightTheme() {
    final base = ThemeData(colorScheme: lightColorScheme, useMaterial3: true);

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Pretendard',
          displayColor: _neutralText,
          bodyColor: _neutralText,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: _neutralSubtitle,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: _neutralSubtitle,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackground,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: _surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _surfaceBackground,
        foregroundColor: _neutralText,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _brandBlue,
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _surfaceBackground,
        selectedColor: _brandBlueLight,
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDFE7F5)),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: _brandBlue,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: const Color(0xFFE6EDF8),
        thickness: 1,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
