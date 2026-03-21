import 'package:flutter/material.dart';

enum AppPaletteKey { aquaDrive, sunsetShift, limeSpark }

@immutable
class AppPalette {
  const AppPalette({
    required this.key,
    required this.name,
    required this.primary,
    required this.primarySoftLight,
    required this.primarySoftDark,
    required this.accent,
    required this.accentSoftLight,
    required this.accentSoftDark,
  });

  final AppPaletteKey key;
  final String name;
  final Color primary;
  final Color primarySoftLight;
  final Color primarySoftDark;
  final Color accent;
  final Color accentSoftLight;
  final Color accentSoftDark;
}

abstract final class AppColors {
  static const AppPalette aquaDrive = AppPalette(
    key: AppPaletteKey.aquaDrive,
    name: 'Aqua Drive',
    primary: Color(0xFF0B8E8C),
    primarySoftLight: Color(0xFFE6F6F6),
    primarySoftDark: Color(0xFF1A3437),
    accent: Color(0xFF2B6CFF),
    accentSoftLight: Color(0xFFEAF0FF),
    accentSoftDark: Color(0xFF1D2C4A),
  );

  static const AppPalette sunsetShift = AppPalette(
    key: AppPaletteKey.sunsetShift,
    name: 'Sunset Shift',
    primary: Color(0xFFE56A3A),
    primarySoftLight: Color(0xFFFFEBDD),
    primarySoftDark: Color(0xFF40251B),
    accent: Color(0xFF3D7BFF),
    accentSoftLight: Color(0xFFE9F0FF),
    accentSoftDark: Color(0xFF1A2B4F),
  );

  static const AppPalette limeSpark = AppPalette(
    key: AppPaletteKey.limeSpark,
    name: 'Lime Spark',
    primary: Color(0xFF2CA45A),
    primarySoftLight: Color(0xFFE7F8ED),
    primarySoftDark: Color(0xFF1D3727),
    accent: Color(0xFF008EA8),
    accentSoftLight: Color(0xFFE3F7FC),
    accentSoftDark: Color(0xFF153843),
  );

  static const List<AppPalette> palettes = <AppPalette>[
    aquaDrive,
    sunsetShift,
    limeSpark,
  ];

  // Default palette for the app UI.
  static const AppPalette activePalette = aquaDrive;

  static Color get primary => activePalette.primary;
  static const Color warning = Color(0xFFD0463A);

  static Color primaryTone(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF2FC2C0)
        : activePalette.primary;
  }

  static Color primarySoft(Brightness brightness) {
    return brightness == Brightness.dark
        ? activePalette.primarySoftDark
        : activePalette.primarySoftLight;
  }

  static Color accent(Brightness brightness) => activePalette.accent;

  static Color accentSoft(Brightness brightness) {
    return brightness == Brightness.dark
        ? activePalette.accentSoftDark
        : activePalette.accentSoftLight;
  }

  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF0F1627)
        : const Color(0xFFF4F7FB);
  }

  static Color card(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF182033)
        : Colors.white;
  }

  static Color text(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFF3F7FF)
        : const Color(0xFF0E1B2A);
  }

  static Color secondaryText(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFB6C2D9)
        : const Color(0xFF5C6C80);
  }

  static Color border(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF2B3854)
        : const Color(0xFFE3EAF3);
  }

  static Color chipBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF1E2940)
        : const Color(0xFFF7F9FC);
  }

  static Color star(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFFFFCB59)
        : const Color(0xFFF5A623);
  }

  static Color successForeground(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF7FE39C)
        : const Color(0xFF2E7D32);
  }

  static Color successBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF1F3A2A)
        : const Color(0xFFE8F5E9);
  }

  static Color warningBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF432028)
        : const Color(0xFFFFEBEE);
  }

  static Color primarySoftOf(BuildContext context) {
    return primarySoft(Theme.of(context).brightness);
  }

  static Color primaryToneOf(BuildContext context) {
    return primaryTone(Theme.of(context).brightness);
  }

  static Color accentOf(BuildContext context) {
    return accent(Theme.of(context).brightness);
  }

  static Color accentSoftOf(BuildContext context) {
    return accentSoft(Theme.of(context).brightness);
  }

  static Color textOf(BuildContext context) {
    return text(Theme.of(context).brightness);
  }

  static Color secondaryTextOf(BuildContext context) {
    return secondaryText(Theme.of(context).brightness);
  }

  static Color chipBackgroundOf(BuildContext context) {
    return chipBackground(Theme.of(context).brightness);
  }

  static Color borderOf(BuildContext context) {
    return border(Theme.of(context).brightness);
  }

  static Color starOf(BuildContext context) {
    return star(Theme.of(context).brightness);
  }

  static Color successForegroundOf(BuildContext context) {
    return successForeground(Theme.of(context).brightness);
  }

  static Color successBackgroundOf(BuildContext context) {
    return successBackground(Theme.of(context).brightness);
  }

  static Color warningBackgroundOf(BuildContext context) {
    return warningBackground(Theme.of(context).brightness);
  }
}
