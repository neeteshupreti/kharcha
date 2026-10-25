import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Left-aligned placeholder for screens or sections with nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.gutter,
      Spacing.xxl,
      Spacing.gutter,
      0,
    ),
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Sizes.minTapTarget,
            height: Sizes.minTapTarget,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.lg),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(message, style: theme.textTheme.bodyMedium),
          if (action != null) ...[
            const SizedBox(height: Spacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
