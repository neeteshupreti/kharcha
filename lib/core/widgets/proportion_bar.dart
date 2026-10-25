import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A thin horizontal bar showing [fraction] (0 to 1) of a full track.
class ProportionBar extends StatelessWidget {
  const ProportionBar({super.key, required this.fraction, required this.fill});

  final double fraction;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sizes.barHeight / 2),
      child: SizedBox(
        height: Sizes.barHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.barTrack),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0).toDouble(),
              child: ColoredBox(color: fill),
            ),
          ],
        ),
      ),
    );
  }
}
