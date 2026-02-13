import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Life Buddy design system - Inspired by Figma design
/// Mindful Lab Palette with iOS aesthetics
class AppTheme {
  static const _appFontFamily = 'LifeSans';

  // iOS Light/Dark backgrounds
  static const _surfaceBackgroundLight = Color(0xFFF2F2F7); // iOS Light BG
  static const _surfaceBackgroundDark = Color(0xFF0F1419); // Midnight Blue

  // Muted text colors
  static const _neutralSubtitleLight = Color(0xFF8E8E93); // iOS Gray
  static const _neutralSubtitleDark = Color(0xFFA1A8B5);

  // Life Buddy Brand Colors - Mindful Lab Palette

  // Primary Colors
  static const eucalyptus = Color(0xFF52C9A5); // Primary green
  static const eucalyptusLight = Color(0xFF6FD4B3);
  static const eucalyptusDark = Color(0xFF42A689);

  static const teal = Color(0xFF4ECDC4); // Primary teal
  static const tealLight = Color(0xFF6FD9D1);
  static const tealDark = Color(0xFF3FB3AC);

  // Energetic Accents
  static const coral = Color(0xFFFF6B6B); // Move/Energy
  static const coralLight = Color(0xFFFF8585);
  static const coralDark = Color(0xFFFF5252);

  static const electricViolet = Color(0xFFB06FF9); // Rest/Sleep
  static const electricVioletLight = Color(0xFFC18CFA);
  static const electricVioletDark = Color(0xFF9F5AE6);

  static const lime = Color(0xFFA8E063); // Journal/Growth
  static const limeLight = Color(0xFFB8E67F);
  static const limeDark = Color(0xFF95CC54);

  // Activity-specific colors (for backward compatibility)
  static const accentBlue = teal; // Focus
  static const accentGreen = coral; // Workout/Move
  static const accentPurple = electricViolet; // Sleep/Rest
  static const accentOrange = lime; // Journal

  static ColorScheme get _fallbackLightScheme => const ColorScheme(
        brightness: Brightness.light,
        // Life Buddy primary - Eucalyptus/Teal blend
        primary: eucalyptus, // #52C9A5
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD4F4E9), // Light eucalyptus tint
        onPrimaryContainer: Color(0xFF064E3B),
        // Secondary - Teal accent
        secondary: teal, // #4ECDC4
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD4F4F2), // Light teal tint
        onSecondaryContainer: Color(0xFF0A3836),
        // Tertiary - Coral for energy
        tertiary: coral, // #FF6B6B
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFFE5E5),
        onTertiaryContainer: Color(0xFF7F1D1D),
        // Error - Using coral
        error: coral, // #FF6B6B
        onError: Colors.white,
        errorContainer: Color(0xFFFFE5E5),
        onErrorContainer: Color(0xFF7F1D1D),
        // iOS-style surface colors
        surface: Colors.white, // #FFFFFF
        onSurface: Colors.black, // #000000
        surfaceBright: Colors.white,
        surfaceContainerLowest: _surfaceBackgroundLight, // #F2F2F7
        surfaceContainerHighest: Color(0xFFE5E5EA), // iOS secondary bg
        onSurfaceVariant: Color(0xFF8E8E93), // iOS gray
        outline: Color(0xFFC6C6C8), // iOS separator
        shadow: Colors.black,
        inverseSurface: Color(0xFF1C1C1E),
        onInverseSurface: Colors.white,
        inversePrimary: eucalyptusLight,
        surfaceTint: Colors.transparent,
      ).harmonized();

  static ColorScheme get _fallbackDarkScheme => const ColorScheme(
        brightness: Brightness.dark,
        // Life Buddy dark mode - Lighter eucalyptus
        primary: eucalyptusLight, // #6FD4B3
        onPrimary: Color(0xFF064E3B),
        primaryContainer: Color(0xFF0A6B53), // Darker eucalyptus
        onPrimaryContainer: eucalyptusLight,
        // Dark mode secondary - Light teal
        secondary: tealLight, // #6FD9D1
        onSecondary: Color(0xFF0A3836),
        secondaryContainer: Color(0xFF0F4D4A),
        onSecondaryContainer: tealLight,
        // Dark mode tertiary - Light coral
        tertiary: coralLight, // #FF8585
        onTertiary: Color(0xFF7F1D1D),
        tertiaryContainer: Color(0xFF991B1B),
        onTertiaryContainer: coralLight,
        // Dark mode error
        error: coralLight, // #FF8585
        onError: Color(0xFF7F1D1D),
        errorContainer: Color(0xFF991B1B),
        onErrorContainer: coralLight,
        // Dark gradient surfaces - matching Figma
        surface: Color(0xFF111318), // Dark card bg
        onSurface: Colors.white,
        surfaceDim: Color(0xFF0A0E14), // Darkest gradient
        surfaceContainerLowest: _surfaceBackgroundDark, // #0F1419
        surfaceContainerHighest: Color(0xFF1C1C1E), // Lighter dark surface
        onSurfaceVariant: Color(0xFFA1A8B5),
        outline: Color(0xFF4B5563),
        shadow: Colors.black,
        inverseSurface: Color(0xFFF2F2F7),
        onInverseSurface: Colors.black,
        inversePrimary: eucalyptus,
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

    // iOS Typography system
    final textTheme = base.textTheme
        .apply(
          fontFamily: _appFontFamily,
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
        )
        .copyWith(
          // iOS Large Title (34px, bold) -> displayLarge
          displayLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0.34, // 0.01em
          ),
          // iOS Title 1 (28px, bold) -> displayMedium
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
          ),
          // iOS Title 2 (22px, semibold) -> headlineLarge
          headlineLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0,
          ),
          // iOS Title 3 (20px, semibold) -> headlineMedium
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0,
          ),
          // iOS Headline (17px, semibold) -> headlineSmall
          headlineSmall: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
          // iOS Body (17px, regular) -> titleLarge
          titleLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
          ),
          // iOS Callout (16px, regular) -> titleMedium
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
          // iOS Subheadline (15px, regular) -> titleSmall
          titleSmall: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
          ),
          // iOS Body (17px, regular) -> bodyLarge
          bodyLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
            color: _neutralSubtitleLight,
          ),
          // iOS Callout (16px, regular) -> bodyMedium
          bodyMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
            color: _neutralSubtitleLight,
          ),
          // iOS Footnote (13px, regular) -> bodySmall
          bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.38,
            letterSpacing: 0,
            color: _neutralSubtitleLight,
          ),
          // iOS Subheadline (15px, regular) -> labelLarge
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
          ),
          // iOS Caption1 (12px, regular) -> labelMedium
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.33,
            letterSpacing: 0,
          ),
          // iOS Caption2 (11px, regular) -> labelSmall
          labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.27,
            letterSpacing: 0,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundLight,
      textTheme: textTheme,
      // iOS Card design - minimal shadows, clean borders
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // iOS style 12px
          side: BorderSide.none, // No border for iOS cards
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      // InkSparkle depends on a shader manifest that can fail on some
      // Windows test runtimes. Use InkRipple to keep interaction feedback
      // stable across CI/dev hosts.
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData darkTheme({ColorScheme? dynamicColor}) {
    final scheme = (dynamicColor?.harmonized() ?? _fallbackDarkScheme).copyWith(
      surface: const Color(0xFF111318),
      surfaceContainerLowest: _surfaceBackgroundDark,
    );

    final base = ThemeData(
      colorScheme: scheme,
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    // iOS Typography system - Dark mode
    final textTheme = base.textTheme
        .apply(
          fontFamily: _appFontFamily,
          displayColor: scheme.onSurface,
          bodyColor: scheme.onSurface,
        )
        .copyWith(
          // iOS Large Title (34px, bold) -> displayLarge
          displayLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0.34,
            color: Colors.white,
          ),
          // iOS Title 1 (28px, bold) -> displayMedium
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Title 2 (22px, semibold) -> headlineLarge
          headlineLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Title 3 (20px, semibold) -> headlineMedium
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Headline (17px, semibold) -> headlineSmall
          headlineSmall: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Body (17px, regular) -> titleLarge
          titleLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Callout (16px, regular) -> titleMedium
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Subheadline (15px, regular) -> titleSmall
          titleSmall: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Body (17px, regular) -> bodyLarge
          bodyLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
            color: _neutralSubtitleDark,
          ),
          // iOS Callout (16px, regular) -> bodyMedium
          bodyMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
            color: _neutralSubtitleDark,
          ),
          // iOS Footnote (13px, regular) -> bodySmall
          bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.38,
            letterSpacing: 0,
            color: _neutralSubtitleDark,
          ),
          // iOS Subheadline (15px, regular) -> labelLarge
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.47,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Caption1 (12px, regular) -> labelMedium
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.33,
            letterSpacing: 0,
            color: Colors.white,
          ),
          // iOS Caption2 (11px, regular) -> labelSmall
          labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.27,
            letterSpacing: 0,
            color: Colors.white,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _surfaceBackgroundDark,
      textTheme: textTheme,
      // iOS Card design - Dark mode
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // iOS style 12px
          side: BorderSide.none, // No border for iOS cards
        ),
        shadowColor: Colors.black.withValues(alpha: 0.2),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      // Keep dark theme splash behavior aligned with light theme for
      // cross-platform widget-test stability.
      splashFactory: InkRipple.splashFactory,
    );
  }
}
