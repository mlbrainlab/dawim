import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Builds the app's single ThemeData (no Cupertino/adaptive switching, per
/// CLAUDE.md non-negotiable #4 — one branded UI on both platforms).
abstract final class AppTheme {
  static ThemeData light() {
    final textTheme = _buildTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D5B)),
      // Root fallback: every unstyled Material widget (dialogs, snackbars,
      // tooltips, default AboutDialog) must resolve to our own fonts, never
      // fall back to Roboto/Noto. See CLAUDE.md non-negotiable #2.
      fontFamily: AppFonts.sans,
      fontFamilyFallback: const <String>[AppFonts.sans, AppFonts.serifDisplay],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }

  /// Every TextTheme field is set explicitly. Leaving any field unset lets
  /// Flutter's Typography.material2021 defaults leak Roboto/NotoSans back in
  /// for that field, silently reintroducing the banned fonts.
  static TextTheme _buildTextTheme() {
    const display = AppFonts.serifDisplay;
    const body = AppFonts.sans;

    TextStyle style(String family, double size, FontWeight weight, {double? height}) {
      return TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, height: height);
    }

    return TextTheme(
      displayLarge: style(display, 57, FontWeight.w400),
      displayMedium: style(display, 45, FontWeight.w400),
      displaySmall: style(display, 36, FontWeight.w400),
      headlineLarge: style(display, 32, FontWeight.w400),
      headlineMedium: style(display, 28, FontWeight.w400),
      headlineSmall: style(display, 24, FontWeight.w400),
      titleLarge: style(display, 22, FontWeight.w500),
      titleMedium: style(display, 16, FontWeight.w500),
      titleSmall: style(display, 14, FontWeight.w500),
      bodyLarge: style(body, 16, FontWeight.w400),
      bodyMedium: style(body, 14, FontWeight.w400),
      bodySmall: style(body, 12, FontWeight.w400),
      labelLarge: style(body, 14, FontWeight.w500),
      labelMedium: style(body, 12, FontWeight.w500),
      labelSmall: style(body, 11, FontWeight.w500),
    );
  }
}
