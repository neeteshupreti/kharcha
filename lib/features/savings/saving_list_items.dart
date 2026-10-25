import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:flutter/material.dart';

/// A single saving row in the savings list. The per-day grouping header is
/// shared with the expenses list (see [DayHeading]).
class SavingTile extends StatelessWidget {
  const SavingTile({
    super.key,
    required this.saving,
    required this.currency,
    required this.onTap,
    this.onDelete,
  });

  final Saving saving;
  final CurrencyOption currency;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.gutter,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: Sizes.glyphBox,
                height: Sizes.glyphBox,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  saving.category.icon,
                  size: Sizes.glyphIcon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saving.category.label, style: textTheme.bodyLarge),
                    if (saving.note.isNotEmpty)
                      Text(
                        saving.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                currency.format(saving.amountMinor),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: AppTypography.medium,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
