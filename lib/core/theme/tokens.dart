import 'package:flutter/material.dart';

/// Spacing scale. Every gap and padding in the app comes from here.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal gutter used by every screen.
  static const double gutter = xl;
}

/// Corner radii. Deliberately small; nothing exceeds 12.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
}

/// Fixed sizes shared by several widgets.
abstract final class Sizes {
  static const double minTapTarget = 48;
  static const double glyphBox = 40;
  static const double glyphIcon = 20;
  static const double barHeight = 6;
  static const double navBarHeight = 68;
  static const double percentColumn = 40;
  static const double monthLabelColumn = 44;
}

/// Type scale: display / title / body / caption, three weights only.
abstract final class AppTypography {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      // Display: the one big number on a screen.
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.15,
        fontWeight: semibold,
        letterSpacing: -0.8,
        color: primary,
        fontFeatures: tabularFigures,
      ),
      // Title.
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: semibold,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: semibold,
        color: primary,
      ),
      // Body.
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: regular,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: regular,
        color: secondary,
      ),
      // Caption.
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: regular,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: medium,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: medium,
        letterSpacing: 0.2,
        color: secondary,
      ),
    );
  }
}

/// Semantic colour roles for one theme. Values were chosen to keep body text
/// at or above 4.5:1 against the surface it sits on.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surfaceRaised,
    required this.fill,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.expense,
    required this.positive,
    required this.danger,
    required this.onDanger,
    required this.barTrack,
    required this.barMuted,
  });

  final Color background;
  final Color surfaceRaised;
  final Color fill;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color accentSubtle;
  final Color expense;
  final Color positive;
  final Color danger;
  final Color onDanger;
  final Color barTrack;
  final Color barMuted;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF7F7F5),
    surfaceRaised: Color(0xFFFFFFFF),
    fill: Color(0xFFEEEEEA),
    divider: Color(0xFFDEDED9),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF5C5C63),
    accent: Color(0xFF1F5C4D),
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFFDDEBE6),
    expense: Color(0xFFB4432F),
    positive: Color(0xFF2E7D4F),
    danger: Color(0xFFB3261E),
    onDanger: Color(0xFFFFFFFF),
    barTrack: Color(0xFFE6E6E1),
    barMuted: Color(0xFF9A9AA1),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0E0E10),
    surfaceRaised: Color(0xFF1C1C1F),
    fill: Color(0xFF19191C),
    divider: Color(0xFF2A2A2E),
    textPrimary: Color(0xFFF2F2F3),
    textSecondary: Color(0xFFA1A1A8),
    accent: Color(0xFF6FB39F),
    onAccent: Color(0xFF0E0E10),
    accentSubtle: Color(0xFF1F332D),
    expense: Color(0xFFE58A78),
    positive: Color(0xFF6DBE8D),
    danger: Color(0xFFF2867E),
    onDanger: Color(0xFF0E0E10),
    barTrack: Color(0xFF232327),
    barMuted: Color(0xFF5A5A61),
  );
}
