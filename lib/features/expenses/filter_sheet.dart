import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the filter sheet. Resolves to the chosen filter, or null if dismissed.
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context,
  ExpenseFilter current,
) {
  return showModalBottomSheet<ExpenseFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

/// Quick date range presets
enum QuickDateRange {
  today,
  thisMonth,
  thisYear,
  custom,
}

/// Extension to get display name for quick date ranges
extension QuickDateRangeExtension on QuickDateRange {
  String get displayName {
    switch (this) {
      case QuickDateRange.today:
        return 'Today';
      case QuickDateRange.thisMonth:
        return 'This Month';
      case QuickDateRange.thisYear:
        return 'This Year';
      case QuickDateRange.custom:
        return 'Custom';
    }
  }

  /// Convert quick date range to actual DateTimeRange
  DateTimeRange toDateTimeRange() {
    final now = dateOnly(DateTime.now());
    switch (this) {
      case QuickDateRange.today:
        return DateTimeRange(start: now, end: now);
      case QuickDateRange.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: now);
      case QuickDateRange.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return DateTimeRange(start: startOfYear, end: now);
      case QuickDateRange.custom:
        // Should not be used directly, use custom picker instead
        return DateTimeRange(start: DateTime(2000), end: now);
    }
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final ExpenseFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _range = widget.initial.range;
  late ExpenseCategory? _category = widget.initial.category;
  QuickDateRange? _quickRange;

  @override
  void initState() {
    super.initState();
    _quickRange = _getQuickRangeFromDateTimeRange(_range);
  }

  QuickDateRange? _getQuickRangeFromDateTimeRange(DateTimeRange? range) {
    if (range == null) return null;
    final now = dateOnly(DateTime.now());
    final todayRange = DateTimeRange(start: now, end: now);
    if (range.start == todayRange.start && range.end == todayRange.end) {
      return QuickDateRange.today;
    }
    final thisMonthRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    if (range.start == thisMonthRange.start && range.end == thisMonthRange.end) {
      return QuickDateRange.thisMonth;
    }
    final thisYearRange = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: now,
    );
    if (range.start == thisYearRange.start && range.end == thisYearRange.end) {
      return QuickDateRange.thisYear;
    }
    return null;
  }

  void _selectQuickRange(QuickDateRange? quickRange) {
    HapticFeedback.selectionClick();
    setState(() {
      _quickRange = quickRange;
      if (quickRange != null && quickRange != QuickDateRange.custom) {
        _range = quickRange.toDateTimeRange();
      } else {
        _range = null;
      }
    });
  }

  Future<void> _pickRange() async {
    final today = dateOnly(DateTime.now());
    final current = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Filter by date range',
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: current.start,
              end: current.end.isAfter(today) ? today : current.end,
            ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _quickRange = QuickDateRange.custom;
      _range = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
  }

  void _selectCategory(ExpenseCategory? category) {
    HapticFeedback.selectionClick();
    setState(() => _category = category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final range = _range;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.sm,
        Spacing.gutter,
        Spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filter transactions', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.xl),
          Text('Date range', style: textTheme.labelMedium),
          const SizedBox(height: Spacing.sm),
          // Quick date range buttons
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final quickRange in QuickDateRange.values)
                FilterChip(
                  label: Text(quickRange.displayName),
                  selected: _quickRange == quickRange,
                  onSelected: (selected) => _selectQuickRange(selected ? quickRange : null),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Custom date range picker
          if (_quickRange == QuickDateRange.custom || _quickRange == null)
            InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Ink(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                padding: const EdgeInsets.only(left: Spacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Sizes.minTapTarget,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          range == null
                              ? 'Select custom date range'
                              : Formatters.rangeLabel(range),
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (range != null)
                        IconButton(
                          tooltip: 'Clear date range',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() {
                            _range = null;
                            _quickRange = null;
                          }),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(Spacing.lg),
                          child: Icon(Icons.calendar_today_outlined, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: Spacing.xl),
          Text('Category', style: textTheme.labelMedium),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => _selectCategory(null),
              ),
              for (final category in ExpenseCategory.values)
                ChoiceChip(
                  avatar: Icon(category.icon),
                  label: Text(category.label),
                  selected: _category == category,
                  onSelected: (_) => _selectCategory(category),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _range = null;
                  _category = null;
                }),
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  ExpenseFilter(range: _range, category: _category),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
