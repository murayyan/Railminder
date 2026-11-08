import 'package:flutter/material.dart';

/// Palette and type scale transcribed from DESIGN.md.
///
/// Dark mode is derived, not invented: same identity, lowered luminance so the
/// screen does not glare when opened in a dim carriage at night.
class AppColors {
  static const Color accent = Color(0xFFE31837);
  static const Color navy = Color(0xFF121C2E);
  static const Color secondaryText = Color(0xFF5B6472);
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD7DCE3);
  static const Color waiting = Color(0xFFB26B00);

  static const Color darkBackground = Color(0xFF0E1420);
  static const Color darkSurface = Color(0xFF16202F);
  static const Color darkText = Color(0xFFF2F4F7);
  static const Color darkSecondaryText = Color(0xFFA5AFBF);
  static const Color darkBorder = Color(0xFF2A3446);
  static const Color darkWaiting = Color(0xFFE0A64B);
}

class AppTheme {
  static const double radiusControl = 10;
  static const double radiusCard = 14;
  static const double minTapTarget = 44;

  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    text: AppColors.navy,
    secondary: AppColors.secondaryText,
    border: AppColors.border,
    waiting: AppColors.waiting,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    text: AppColors.darkText,
    secondary: AppColors.darkSecondaryText,
    border: AppColors.darkBorder,
    waiting: AppColors.darkWaiting,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color secondary,
    required Color border,
    required Color waiting,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: text,
        outline: border,
        error: AppColors.accent,
      ),
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: text, height: 1.15),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: text, height: 1.25),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text, height: 1.3),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: text, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: text, height: 1.45),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text, height: 1.2),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondary, height: 1.35),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, AppTheme.minTapTarget),
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, AppTheme.minTapTarget),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: secondary, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minVerticalPadding: 12,
        iconColor: secondary,
        textColor: text,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: TextStyle(color: background, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Semantic status colours are passed alongside an icon and a text label, never
/// used as the only signal (DESIGN.md, status table).
class StatusPalette {
  final Color waiting;
  final Color active;
  final Color error;

  const StatusPalette({
    required this.waiting,
    required this.active,
    required this.error,
  });

  static StatusPalette of(Brightness brightness) => brightness == Brightness.dark
      ? const StatusPalette(
          waiting: AppColors.darkWaiting,
          active: AppColors.darkText,
          error: AppColors.accent,
        )
      : const StatusPalette(
          waiting: AppColors.waiting,
          active: AppColors.navy,
          error: AppColors.accent,
        );
}
