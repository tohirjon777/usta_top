import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
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
      iconTheme: IconThemeData(color: text),
      primaryIconTheme: IconThemeData(color: text),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: text,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: text,
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
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.3),
        ),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackground(brightness),
        side: BorderSide(color: border),
        selectedColor: primarySoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primarySoft,
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
      dividerColor: border,
    );
  }
}
