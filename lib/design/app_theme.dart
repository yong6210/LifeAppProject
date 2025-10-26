import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralised design tokens. Updated for 2025 spatial/glassmorphism trends and
/// dynamic colour harmonisation across Android/iOS.
class AppTheme {
  static const _surfaceBackgroundLight = Color(0xFFF4F5FA);
  static const _surfaceBackgroundDark = Color(0xFF10121A);
  static const _neutralSubtitleLight = Color(0xFF5F6475);
  static const _neutralSubtitleDark = Color(0xFFC6CAD8);

  static ColorScheme get _fallbackLightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1460FF),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFADC7FF),
        onPrimaryContainer: Color(0xFF041A4C),
        secondary: Color(0xFF5260FF),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD7DBFF),
        onSecondaryContainer: Color(0xFF192066),
        tertiary: Color(0xFF00C6AE),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFBDF6EC),
        onTertiaryContainer: Color(0xFF003730),
        error: Color(0xFFEF5353),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1C1E22),
        surfaceBright: Color(0xFFFFFFFF),
        surfaceContainerLowest: _surfaceBackgroundLight,
        surfaceContainerHighest: Color(0xFFE0E5F2),
        onSurfaceVariant: Color(0xFF424858),
        outline: Color(0xFFB6BCCB),
        shadow: Colors.black,
        inverseSurface: Color(0xFF2A2E38),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFFADC7FF),
        surfaceTint: Color(0xFF1460FF),
      ).harmonized();

  static ColorScheme get _fallbackDarkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFADC7FF),
        onPrimary: Color(0xFF032865),
        primaryContainer: Color(0xFF11449B),
        onPrimaryContainer: Color(0xFFD9E2FF),
        secondary: Color(0xFFC1C5FF),
        onSecondary: Color(0xFF0E1453),
        secondaryContainer: Color(0xFF2E3486),
        onSecondaryContainer: Color(0xFFE0E1FF),
        tertiary: Color(0xFF80F0DB),
        onTertiary: Color(0xFF00382F),
        tertiaryContainer: Color(0xFF005246),
        onTertiaryContainer: Color(0xFF9EF5E5),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF171922),
        onSurface: Color(0xFFE1E3EB),
        surfaceDim: Color(0xFF10121A),
        surfaceContainerLowest: _surfaceBackgroundDark,
        surfaceContainerHighest: Color(0xFF424658),
        onSurfaceVariant: Color(0xFFC4C8D6),
        outline: Color(0xFF8B8FA0),
        shadow: Colors.black,
        inverseSurface: Color(0xFFE4E6F0),
        onInverseSurface: Color(0xFF101217),
        inversePrimary: Color(0xFF1F4BA6),
        surfaceTint: Color(0xFFADC7FF),
      ).harmonized();

  static ThemeData lightTheme({ColorScheme? dynamicColor}) {
    final scheme =
        (dynamicColor?.harmonized() ?? _fallbackLightScheme).copyWith(
      surface: Colors.white.withValues(alpha: 0.92),
      surfaceContainerLowest: _surfaceBackgroundLight,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Pretendard',
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
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
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: _neutralSubtitleLight,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: _neutralSubtitleLight,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundLight,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 6,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: Brightness.light == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: scheme.primary.withValues(alpha: 0.25),
          elevation: 6,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.8),
          elevation: 0,
          foregroundColor: scheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.7),
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.primary,
        tileColor: scheme.surface.withValues(alpha: 0.82),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.35);
          }
          return scheme.outline.withValues(alpha: 0.2);
        }),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData darkTheme({ColorScheme? dynamicColor}) {
    final scheme =
        (dynamicColor?.harmonized() ?? _fallbackDarkScheme).copyWith(
      surface: const Color(0xFF1D1F29).withValues(alpha: 0.92),
      surfaceContainerLowest: _surfaceBackgroundDark,
    );

    final base = ThemeData(
      colorScheme: scheme,
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Pretendard',
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: _neutralSubtitleDark,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: _neutralSubtitleDark,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundDark,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 10,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: scheme.primary.withValues(alpha: 0.3),
          elevation: 6,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.3),
          foregroundColor: scheme.onSecondaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.6),
        selectedColor: scheme.primary.withValues(alpha: 0.25),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.primary,
        tileColor: scheme.surface.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant.withValues(alpha: 0.7);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.35);
          }
          return scheme.outline.withValues(alpha: 0.3);
        }),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        thickness: 1,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
