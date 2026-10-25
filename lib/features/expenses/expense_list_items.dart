import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';

class DayHeading extends StatelessWidget {
  const DayHeading({super.key, required this.date, required this.total});

  final DateTime date;
  final String total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.xl,
        Spacing.gutter,
        Spacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Formatters.dayHeading(date),
              style: textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Text(
            total,
            style: textTheme.labelMedium?.copyWith(
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    required this.onTap,
    this.onDelete,
  });

  final Expense expense;
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
                  expense.category.icon,
                  size: Sizes.glyphIcon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.category.label, style: textTheme.bodyLarge),
                    if (expense.note.isNotEmpty)
                      Text(
                        expense.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                currency.format(expense.amountMinor),
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
