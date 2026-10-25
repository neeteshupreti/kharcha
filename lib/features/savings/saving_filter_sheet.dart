import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/features/expenses/filter_sheet.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:expense_tracker/models/saving_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the savings filter sheet. Resolves to the chosen filter, or null if
/// dismissed. Mirrors the expenses [showExpenseFilterSheet] but filters by
/// [SavingCategory] instead.
Future<SavingFilter?> showSavingFilterSheet(
  BuildContext context,
  SavingFilter current,
) {
  return showModalBottomSheet<SavingFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SavingFilterSheet(initial: current),
  );
}

class _SavingFilterSheet extends StatefulWidget {
  const _SavingFilterSheet({required this.initial});

  final SavingFilter initial;

  @override
  State<_SavingFilterSheet> createState() => _SavingFilterSheetState();
}

class _SavingFilterSheetState extends State<_SavingFilterSheet> {
  late DateTimeRange? _range = widget.initial.range;
  late SavingCategory? _category = widget.initial.category;
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
    if (range.start == thisMonthRange.start &&
        range.end == thisMonthRange.end) {
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

  void _selectCategory(SavingCategory? category) {
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
          Text('Filter savings', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.xl),
          Text('Date range', style: textTheme.labelMedium),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final quickRange in QuickDateRange.values)
                FilterChip(
                  label: Text(quickRange.displayName),
                  selected: _quickRange == quickRange,
                  onSelected: (selected) =>
                      _selectQuickRange(selected ? quickRange : null),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
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
              for (final category in SavingCategory.values)
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
                  SavingFilter(range: _range, category: _category),
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
