import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Refined design system with sophisticated color palette and modern aesthetics.
/// Removes AI-generated feel with carefully curated colors and professional spacing.
class AppTheme {
  // Refined neutral backgrounds - softer and more sophisticated
  static const _surfaceBackgroundLight = Color(0xFFFAFAFC);
  static const _surfaceBackgroundDark = Color(0xFF0A0B0F);

  // Professional subtitle colors with better readability
  static const _neutralSubtitleLight = Color(0xFF6B7280);
  static const _neutralSubtitleDark = Color(0xFFA1A8B5);

  // Accent colors for feature categorization - more refined palette
  static const accentBlue = Color(0xFF4F7CFF);      // Focus
  static const accentGreen = Color(0xFF10B981);     // Workout
  static const accentPurple = Color(0xFF8B5CF6);    // Sleep
  static const accentOrange = Color(0xFFF59E0B);    // Rest

  static ColorScheme get _fallbackLightScheme => const ColorScheme(
        brightness: Brightness.light,
        // More refined primary - less saturated, more professional
        primary: Color(0xFF4F7CFF),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0E9FF),
        onPrimaryContainer: Color(0xFF0D1B3E),
        // Softer secondary colors
        secondary: Color(0xFF6B7CFF),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE5E8FF),
        onSecondaryContainer: Color(0xFF1A1D3A),
        // Balanced tertiary with better contrast
        tertiary: Color(0xFF10B981),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFD1FAE5),
        onTertiaryContainer: Color(0xFF064E3B),
        // Refined error colors
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFFFFE5E5),
        onErrorContainer: Color(0xFF7F1D1D),
        // Clean surface colors
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1F2937),
        surfaceBright: Color(0xFFFFFFFF),
        surfaceContainerLowest: _surfaceBackgroundLight,
        surfaceContainerHighest: Color(0xFFF3F4F6),
        onSurfaceVariant: Color(0xFF4B5563),
        outline: Color(0xFFD1D5DB),
        shadow: Colors.black,
        inverseSurface: Color(0xFF1F2937),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFFA5C4FF),
        surfaceTint: Colors.transparent,
      ).harmonized();

  static ColorScheme get _fallbackDarkScheme => const ColorScheme(
        brightness: Brightness.dark,
        // Refined dark mode primary
        primary: Color(0xFF7C9EFF),
        onPrimary: Color(0xFF0A1A3E),
        primaryContainer: Color(0xFF2D4B8C),
        onPrimaryContainer: Color(0xFFE0E9FF),
        // Refined dark mode secondary
        secondary: Color(0xFF8B9AFF),
        onSecondary: Color(0xFF141732),
        secondaryContainer: Color(0xFF3A4470),
        onSecondaryContainer: Color(0xFFE5E8FF),
        // Refined dark mode tertiary
        tertiary: Color(0xFF34D399),
        onTertiary: Color(0xFF064E3B),
        tertiaryContainer: Color(0xFF065F46),
        onTertiaryContainer: Color(0xFFD1FAE5),
        // Refined dark mode error
        error: Color(0xFFF87171),
        onError: Color(0xFF7F1D1D),
        errorContainer: Color(0xFF991B1B),
        onErrorContainer: Color(0xFFFFE5E5),
        // Sophisticated dark surfaces
        surface: Color(0xFF111318),
        onSurface: Color(0xFFE5E7EB),
        surfaceDim: Color(0xFF0A0B0F),
        surfaceContainerLowest: _surfaceBackgroundDark,
        surfaceContainerHighest: Color(0xFF2D3139),
        onSurfaceVariant: Color(0xFFD1D5DB),
        outline: Color(0xFF4B5563),
        shadow: Colors.black,
        inverseSurface: Color(0xFFF3F4F6),
        onInverseSurface: Color(0xFF111827),
        inversePrimary: Color(0xFF4F7CFF),
        surfaceTint: Colors.transparent,
      ).harmonized();

  static ThemeData lightTheme({ColorScheme? dynamicColor}) {
    final scheme =
        (dynamicColor?.harmonized() ?? _fallbackLightScheme).copyWith(
      surface: Colors.white,
      surfaceContainerLowest: _surfaceBackgroundLight,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.light,
    );

    // Refined typography with better hierarchy
    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Pretendard',
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
        )
        .copyWith(
          // Display styles for hero sections
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1.1,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          // Headline styles for section titles
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.2,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.3,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          // Title styles for card headers
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          // Body styles for content
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            letterSpacing: 0.1,
            color: _neutralSubtitleLight,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            letterSpacing: 0.1,
            color: _neutralSubtitleLight,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: _neutralSubtitleLight,
          ),
          // Label styles for UI elements
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundLight,
      textTheme: textTheme,
      // Refined card design - cleaner shadows, better spacing
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        shadowColor: scheme.shadow.withValues(alpha: 0.04),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      // Modern button designs with refined spacing
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
          elevation: 0,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Refined chip design
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Clean list tile design
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.primary,
        tileColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.3);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outline.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData darkTheme({ColorScheme? dynamicColor}) {
    final scheme =
        (dynamicColor?.harmonized() ?? _fallbackDarkScheme).copyWith(
      surface: const Color(0xFF111318),
      surfaceContainerLowest: _surfaceBackgroundDark,
    );

    final base = ThemeData(
      colorScheme: scheme,
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    // Refined dark mode typography - matching light theme hierarchy
    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Pretendard',
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
        )
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1.1,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.2,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.3,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            letterSpacing: 0.1,
            color: _neutralSubtitleDark,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            letterSpacing: 0.1,
            color: _neutralSubtitleDark,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: _neutralSubtitleDark,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundDark,
      textTheme: textTheme,
      // Refined dark card design with subtle borders
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        shadowColor: Colors.transparent,
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
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
          elevation: 0,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.primary,
        tileColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.3);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
