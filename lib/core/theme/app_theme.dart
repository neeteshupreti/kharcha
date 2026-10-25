import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      primaryContainer: palette.accentSubtle,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.accentSubtle,
      onSecondaryContainer: palette.textPrimary,
      error: palette.danger,
      onError: palette.onDanger,
      surface: palette.background,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.background,
      surfaceContainer: palette.fill,
      surfaceContainerHigh: palette.surfaceRaised,
      surfaceContainerHighest: palette.surfaceRaised,
      outline: palette.textSecondary,
      outlineVariant: palette.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.background,
      inversePrimary: palette.accent,
    );

    final textTheme = AppTypography.textTheme(
      primary: palette.textPrimary,
      secondary: palette.textSecondary,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );
    const minimumButtonSize = Size(64, Sizes.minTapTarget);

    OutlineInputBorder inputBorder([Color? color, double width = 1.5]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: palette.textPrimary.withValues(alpha: 0.06),
      highlightColor: palette.textPrimary.withValues(alpha: 0.04),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [AppColors.fromPalette(palette)],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surfaceRaised,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.fill,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.lg,
        ),
        labelStyle: textTheme.labelMedium,
        floatingLabelStyle: textTheme.labelMedium,
        hintStyle: textTheme.bodyLarge?.copyWith(color: palette.textSecondary),
        prefixStyle: textTheme.bodyLarge,
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.danger),
        counterStyle: textTheme.bodySmall,
        border: inputBorder(),
        enabledBorder: inputBorder(),
        focusedBorder: inputBorder(palette.accent),
        errorBorder: inputBorder(palette.danger, 1),
        focusedErrorBorder: inputBorder(palette.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: buttonShape,
          foregroundColor: palette.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(Sizes.minTapTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        elevation: 1,
        focusElevation: 1,
        hoverElevation: 1,
        highlightElevation: 2,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          color: palette.onAccent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: Sizes.navBarHeight,
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: palette.accentSubtle,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? palette.textPrimary : palette.textSecondary,
            fontWeight:
                selected ? AppTypography.semibold : AppTypography.medium,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? palette.accent : palette.textSecondary,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        modalBackgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.divider,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.fill,
        selectedColor: palette.accentSubtle,
        side: BorderSide(color: palette.divider),
        labelStyle: textTheme.labelLarge,
        iconTheme: IconThemeData(color: palette.textSecondary, size: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, Sizes.minTapTarget),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.divider)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? palette.accentSubtle
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? palette.textPrimary
                : palette.textSecondary;
          }),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.textPrimary,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: palette.background,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        circularTrackColor: Colors.transparent,
      ),
    );
  }
}
