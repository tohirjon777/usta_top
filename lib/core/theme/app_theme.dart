import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = AppColors.primaryTone(brightness);
    final Color primarySoft = AppColors.primarySoft(brightness);
    final Color border = AppColors.border(brightness);
    final Color card = AppColors.card(brightness);
    final Color text = AppColors.text(brightness);
    final Color secondaryText = AppColors.secondaryText(brightness);
    final Color accent = AppColors.accent(brightness);
    final Color accentSoft = AppColors.accentSoft(brightness);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      secondaryContainer: accentSoft,
      surface: card,
      onSurface: text,
      error: AppColors.warning,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface(brightness),
      splashFactory: isDark ? InkSparkle.splashFactory : null,
      iconTheme: IconThemeData(color: text),
      primaryIconTheme: IconThemeData(color: text),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -0.8,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -0.55,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.35,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: secondaryText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text),
        actionsIconTheme: IconThemeData(color: text),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(isDark ? 26 : 22)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C253A) : card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 20 : 18),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 20 : 18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDark ? 20 : 18),
          borderSide: BorderSide(color: primary, width: isDark ? 1.5 : 1.3),
        ),
        hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.82)),
        labelStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackground(brightness),
        side: BorderSide(color: border),
        selectedColor: primarySoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDark ? 20 : 18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: isDark ? const Color(0xFF162133) : null,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDark ? 20 : 18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primarySoft,
        surfaceTintColor: Colors.transparent,
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primary);
            }
            return IconThemeData(color: secondaryText);
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            final Color labelColor =
                states.contains(WidgetState.selected) ? primary : secondaryText;
            return TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor,
            );
          },
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: text,
        textColor: text,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1A2334) : card,
        contentTextStyle: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
    );
  }
}
