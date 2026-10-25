import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Custom semantic colours that do not exist in [ColorScheme]. Registered as a
/// [ThemeExtension] so light and dark stay in sync and animate together.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.expense,
    required this.positive,
    required this.danger,
    required this.onDanger,
    required this.barTrack,
    required this.barMuted,
    required this.divider,
  });

  factory AppColors.fromPalette(AppPalette palette) {
    return AppColors(
      expense: palette.expense,
      positive: palette.positive,
      danger: palette.danger,
      onDanger: palette.onDanger,
      barTrack: palette.barTrack,
      barMuted: palette.barMuted,
      divider: palette.divider,
    );
  }

  final Color expense;
  final Color positive;
  final Color danger;
  final Color onDanger;
  final Color barTrack;
  final Color barMuted;
  final Color divider;

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    Color? expense,
    Color? positive,
    Color? danger,
    Color? onDanger,
    Color? barTrack,
    Color? barMuted,
    Color? divider,
  }) {
    return AppColors(
      expense: expense ?? this.expense,
      positive: positive ?? this.positive,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      barTrack: barTrack ?? this.barTrack,
      barMuted: barMuted ?? this.barMuted,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      expense: Color.lerp(expense, other.expense, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      barTrack: Color.lerp(barTrack, other.barTrack, t)!,
      barMuted: Color.lerp(barMuted, other.barMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
