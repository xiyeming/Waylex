import 'package:flutter/material.dart';
import '../../presentation/theme/app_design_tokens.dart';

class AppTheme {
  // ========== Dark ==========

  static ColorScheme _buildDarkColorScheme(AccentColor accent) {
    return ColorScheme.dark(
      // ── Surface 7-layer hierarchy ──
      surface: AppTokens.background,
      surfaceContainerLowest: AppTokens.surface,
      surfaceContainerLow: AppTokens.surfaceVariant,
      surfaceContainer: AppTokens.surfaceHover,
      surfaceContainerHigh: AppTokens.surfacePressed,
      surfaceContainerHighest: AppTokens.surface,

      // ── Text ──
      onSurface: AppTokens.textPrimary,
      onSurfaceVariant: AppTokens.textSecondary,

      // ── Outline ──
      outline: AppTokens.border,

      // ── Primary (Accent) ──
      primary: accent.value,
      onPrimary: AppTokens.background,
      primaryContainer: accent.container,

      // ── Tertiary (AI Accent) ──
      tertiary: AppTokens.ai,
      onTertiary: AppTokens.background,
      tertiaryContainer: const Color(0x1AB48CFF),
      onTertiaryContainer: AppTokens.ai,

      // ── Error ──
      error: AppTokens.error,
      onError: AppTokens.textPrimary,

      // ── Effects ──
      shadow: AppTokens.cardShadow,
      scrim: AppTokens.overlayMedium,
    );
  }

  // ========== Light ==========

  static ColorScheme _buildLightColorScheme(AccentColor accent) {
    return ColorScheme.light(
      // ── Surface 7-layer hierarchy ──
      surface: const Color(0xFFF7F8FA),
      surfaceContainerLowest: const Color(0xFFEAEAEF),
      surfaceContainerLow: const Color(0xFFF0F0F5),
      surfaceContainer: const Color(0xFFEAEAEF),
      surfaceContainerHigh: const Color(0xFFE0E0E5),
      surfaceContainerHighest: const Color(0xFFEAEAEF),

      // ── Text ──
      onSurface: const Color(0xFF1C1B1F),
      onSurfaceVariant: const Color(0xFF5F5F66),

      // ── Outline ──
      outline: const Color(0xFFD0D0D5),

      // ── Primary (Accent) ──
      primary: accent.value,
      onPrimary: Colors.white,
      primaryContainer: accent.container,

      // ── Tertiary (AI Accent) ──
      tertiary: const Color(0xFF7C5CF6),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0x1A7C5CF6),
      onTertiaryContainer: const Color(0xFF7C5CF6),

      // ── Error ──
      error: AppTokens.error,
      onError: Colors.white,

      // ── Effects ──
      shadow: const Color(0x33000000),
      scrim: const Color(0x66000000),
    );
  }

  // ========== Shared Theme Builder ==========

  static ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final textPrimary = cs.onSurface;
    final textHint = isDark ? AppTokens.textHint : const Color(0xFF9E9EAE);
    final dividerColor = isDark ? AppTokens.divider : const Color(0x0D000000);

    final inputFill = isDark ? AppTokens.surfaceVariant : cs.surfaceContainerLow;
    final inputBorder = isDark ? AppTokens.border : cs.outline;
    final menuBg = isDark ? AppTokens.surfaceVariant : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,

      // ── Text Theme ──
      textTheme: TextTheme(
        labelSmall: TextStyle(fontSize: AppTokens.fontCaption, color: textPrimary),
        labelMedium: TextStyle(fontSize: AppTokens.fontCaption, color: textPrimary),
        bodySmall: TextStyle(fontSize: AppTokens.fontBody, color: textPrimary),
        bodyMedium: TextStyle(fontSize: AppTokens.fontBody, color: textPrimary),
        bodyLarge: TextStyle(fontSize: AppTokens.fontLg, color: textPrimary),
        titleSmall: TextStyle(fontSize: AppTokens.fontTitleSm, color: textPrimary),
        titleMedium: TextStyle(fontSize: AppTokens.fontTitleMd, color: textPrimary),
        titleLarge: TextStyle(fontSize: AppTokens.fontTitleLg, color: textPrimary),
      ),

      // ── Card Theme ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: cs.outline, width: 1),
        ),
      ),

      // ── App Bar Theme ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surface,
        titleTextStyle: TextStyle(
          fontSize: AppTokens.fontTitleMd,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),

      // ── Input Decoration Theme ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        filled: true,
        fillColor: inputFill,
        contentPadding: AppTokens.inputContentPadding,
        labelStyle: TextStyle(fontSize: AppTokens.fontCaption, color: textHint),
        hintStyle: TextStyle(fontSize: AppTokens.fontCaption, color: textHint),
      ),

      // ── Dialog Theme ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        titleTextStyle: TextStyle(
          fontSize: AppTokens.fontTitleMd,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),

      // ── Bottom Sheet Theme ──
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusMd),
          ),
        ),
      ),

      // ── Popup Menu Theme ──
      popupMenuTheme: PopupMenuThemeData(
        color: menuBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        elevation: 8,
        shadowColor: AppTokens.menuShadow,
      ),

      // ── Divider Theme ──
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── Switch Theme ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return isDark ? AppTokens.textDisabled : const Color(0xFFBDBDBD);
          }
          return isDark ? AppTokens.switchOffThumb : AppTokens.switchOffThumbLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.hovered)) {
              return cs.primary.withValues(alpha: 0.4);
            }
            return cs.primary.withValues(alpha: 0.3);
          }
          if (states.contains(WidgetState.hovered)) {
            return isDark ? AppTokens.switchOffHover : AppTokens.switchOffHoverLight;
          }
          return isDark ? AppTokens.switchOffTrack : AppTokens.switchOffTrackLight;
        }),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
      ),

      // ── Chip Theme ──
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(
          fontSize: AppTokens.fontCaption,
          color: cs.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.5), width: 1),
        ),
        padding: AppTokens.chipPadding,
      ),

      // ── Icon Theme ──
      iconTheme: IconThemeData(
        color: cs.onSurfaceVariant,
        size: AppTokens.iconMd,
      ),

      // ── Primary Icon Theme ──
      primaryIconTheme: IconThemeData(
        color: cs.onPrimary,
        size: AppTokens.iconMd,
      ),
    );
  }

  // ========== Public Accessors ==========

  static ThemeData light(AccentColor accent) =>
      _buildTheme(_buildLightColorScheme(accent), Brightness.light);

  static ThemeData dark(AccentColor accent) =>
      _buildTheme(_buildDarkColorScheme(accent), Brightness.dark);

  /// Convenience for current theme mode.
  static ThemeData resolve(ThemeMode mode, AccentColor accent) {
    return mode == ThemeMode.light ? light(accent) : dark(accent);
  }
}
