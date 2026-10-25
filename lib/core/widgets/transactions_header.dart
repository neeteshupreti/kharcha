import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A filter bar for a ledger list: a title with a "Filter" action button, and,
/// when a filter is active, a row of chips for the active range/category.
///
/// Shared by the Expenses and Savings list screens. It takes primitive props
/// (already formatted by the caller) so it can work with either [ExpenseFilter]
/// or [SavingFilter] without duplicating UI.
class TransactionsHeader extends StatelessWidget {
  const TransactionsHeader({
    super.key,
    required this.title,
    required this.filterIsActive,
    required this.activeCount,
    required this.rangeText,
    required this.categoryText,
    required this.onOpenFilters,
    required this.onClearRange,
    required this.onClearCategory,
  });

  final String title;
  final bool filterIsActive;
  final int activeCount;

  /// Pre-formatted range label, or null when no range is selected.
  final String? rangeText;

  /// Pre-formatted category label, or null when no category is selected.
  final String? categoryText;

  final VoidCallback onOpenFilters;
  final VoidCallback onClearRange;
  final VoidCallback onClearCategory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showChips = rangeText != null || categoryText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Spacing.gutter,
            right: Spacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              TextButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(
                  filterIsActive ? 'Filter \u00B7 $activeCount' : 'Filter',
                ),
              ),
            ],
          ),
        ),
        if (showChips)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              Spacing.xs,
              Spacing.gutter,
              0,
            ),
            child: Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                if (rangeText != null)
                  InputChip(
                    label: Text(rangeText!),
                    deleteButtonTooltipMessage: 'Remove date filter',
                    onDeleted: onClearRange,
                  ),
                if (categoryText != null)
                  InputChip(
                    label: Text(categoryText!),
                    deleteButtonTooltipMessage: 'Remove category filter',
                    onDeleted: onClearCategory,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
