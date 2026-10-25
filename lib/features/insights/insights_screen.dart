import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/core/widgets/empty_state.dart';
import 'package:expense_tracker/core/widgets/proportion_bar.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/expenses/filter_sheet.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/summaries.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late DateTime _month = monthStart(DateTime.now());
  DateTimeRange? _dateRange;

  void _shiftMonth(int delta) {
    setState(() => _month = addMonths(_month, delta));
  }

  Future<void> _openDateFilter() async {
    final result = await showModalBottomSheet<QuickDateRange>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date range',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Spacing.md),
                Text('Quick options',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final quickRange in QuickDateRange.values)
                      FilterChip(
                        label: Text(quickRange.displayName),
                        selected: _dateRange == null &&
                                quickRange == QuickDateRange.thisMonth
                            ? true
                            : _dateRange != null &&
                                _getQuickRangeFromDateTimeRange(_dateRange) ==
                                    quickRange,
                        onSelected: (selected) {
                          if (selected) {
                            if (quickRange == QuickDateRange.custom) {
                              Navigator.of(context).pop();
                              _pickCustomDateRange();
                            } else {
                              Navigator.of(context).pop(quickRange);
                            }
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result != QuickDateRange.custom) {
      setState(() => _dateRange = result.toDateTimeRange());
    }
  }

  Future<void> _pickCustomDateRange() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Filter by date range',
      initialDateRange: _dateRange,
    );
    if (picked == null) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();
    final savingController = context.watch<SavingController>();
    final currency = context.watch<SettingsController>().currency;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final now = DateTime.now();
    final isCurrentMonth = isSameMonth(_month, now);

    // Use date range if set, otherwise the month the user is viewing.
    final effectiveStart = _dateRange?.start ?? monthStart(_month);
    final effectiveEnd = _dateRange?.end ?? endOfMonth(_month);

    // Check if we're viewing a single month or custom range
    final isSingleMonthView = _dateRange == null ||
        (effectiveStart.year == effectiveEnd.year &&
            effectiveStart.month == effectiveEnd.month);

    // For month-based stats, use the first month in the range
    final statsMonth = isSingleMonthView
        ? DateTime(effectiveStart.year, effectiveStart.month)
        : effectiveStart;

    final total = controller.totalForRange(effectiveStart, effectiveEnd);
    final count = controller.countForRange(effectiveStart, effectiveEnd);
    final categories =
        controller.categoryTotalsForRange(effectiveStart, effectiveEnd);

    final previousMonth = addMonths(statsMonth, -1);
    final previousTotal = controller.totalForMonth(previousMonth);
    final history = controller.monthlyTotals(statsMonth);

    final daysCounted = isCurrentMonth && _dateRange == null
        ? now.day
        : daysBetween(effectiveStart, effectiveEnd) + 1;
    final dailyAverage = daysCounted > 0 ? total ~/ daysCounted : 0;

    // Savings mirror of the expense stats above.
    final savingTotal =
        savingController.totalForRange(effectiveStart, effectiveEnd);
    final savingCount =
        savingController.countForRange(effectiveStart, effectiveEnd);
    final savingCategories =
        savingController.categoryTotalsForRange(effectiveStart, effectiveEnd);
    final previousSavingTotal = savingController.totalForMonth(previousMonth);
    final savingHistory = savingController.monthlyTotals(statsMonth);
    final savingDailyAverage = daysCounted > 0 ? savingTotal ~/ daysCounted : 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kharcha'),
          centerTitle: true,
          actions: [
            TextButton.icon(
              onPressed: _openDateFilter,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_dateRange == null ? 'All time' : 'Filtered'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Savings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Expenses tab
            ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                Spacing.sm,
                Spacing.gutter,
                Spacing.xxl,
              ),
              children: [
                _dateRangeChip(context),
                _monthHeader(context),
                const SizedBox(height: Spacing.lg),
                Text(_dateRange == null ? 'Monthly spendings' : 'Total spent',
                    style: textTheme.bodyMedium),
                const SizedBox(height: Spacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(currency.format(total),
                      style: textTheme.displaySmall),
                ),
                const SizedBox(height: Spacing.sm),
                _ComparisonLine(
                  total: total,
                  previousTotal: previousTotal,
                  previousMonthName: Formatters.monthName(previousMonth),
                ),
                const SizedBox(height: Spacing.xl),
                Wrap(
                  spacing: Spacing.xxl,
                  runSpacing: Spacing.lg,
                  children: [
                    _Stat(
                        label: 'Daily average',
                        value: currency.format(dailyAverage)),
                    _Stat(label: 'Transactions', value: '$count'),
                    _Stat(
                      label: 'Top category',
                      value: categories.isEmpty
                          ? '\u2014'
                          : categories.first.category.label,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xxl),
                Text('By category', style: textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                if (categories.isEmpty)
                  EmptyState(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    icon: Icons.bar_chart_outlined,
                    title:
                        'Nothing recorded in ${Formatters.monthName(_month)}',
                    message:
                        'Expenses you add for this month will be broken down here.',
                  )
                else
                  for (final entry in categories)
                    _CategoryRow(
                      icon: entry.category.icon,
                      label: entry.category.label,
                      totalMinor: entry.totalMinor,
                      monthTotal: total,
                      currency: currency,
                    ),
                if (history.any((month) => month.totalMinor > 0)) ...[
                  const SizedBox(height: Spacing.xxl),
                  Text('Last six months', style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.sm),
                  _MonthHistory(
                    history: history,
                    selectedMonth: _month,
                    currency: currency,
                  ),
                ],
              ],
            ),
            // Savings tab
            ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                Spacing.sm,
                Spacing.gutter,
                Spacing.xxl,
              ),
              children: [
                _dateRangeChip(context),
                _monthHeader(context),
                const SizedBox(height: Spacing.lg),
                Text(_dateRange == null ? 'Monthly savings' : 'Total saved',
                    style: textTheme.bodyMedium),
                const SizedBox(height: Spacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(currency.format(savingTotal),
                      style: textTheme.displaySmall),
                ),
                const SizedBox(height: Spacing.sm),
                _ComparisonLine(
                  total: savingTotal,
                  previousTotal: previousSavingTotal,
                  previousMonthName: Formatters.monthName(previousMonth),
                  subject: 'saving',
                  growthIsPositive: true,
                ),
                const SizedBox(height: Spacing.xl),
                Wrap(
                  spacing: Spacing.xxl,
                  runSpacing: Spacing.lg,
                  children: [
                    _Stat(
                        label: 'Daily average',
                        value: currency.format(savingDailyAverage)),
                    _Stat(label: 'Entries', value: '$savingCount'),
                    _Stat(
                      label: 'Top category',
                      value: savingCategories.isEmpty
                          ? '\u2014'
                          : savingCategories.first.category.label,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xxl),
                Text('By category', style: textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                if (savingCategories.isEmpty)
                  EmptyState(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    icon: Icons.savings_outlined,
                    title:
                        'Nothing recorded in ${Formatters.monthName(_month)}',
                    message:
                        'Savings you add for this period will be broken down here.',
                  )
                else
                  for (final entry in savingCategories)
                    _CategoryRow(
                      icon: entry.category.icon,
                      label: entry.category.label,
                      totalMinor: entry.totalMinor,
                      monthTotal: savingTotal,
                      currency: currency,
                    ),
                if (savingHistory.any((month) => month.totalMinor > 0)) ...[
                  const SizedBox(height: Spacing.xxl),
                  Text('Last six months', style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.sm),
                  _MonthHistory(
                    history: savingHistory,
                    selectedMonth: _month,
                    currency: currency,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeChip(BuildContext context) {
    if (_dateRange == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: InputChip(
              label: Text(Formatters.rangeLabel(_dateRange!)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _dateRange = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCurrentMonth = isSameMonth(_month, DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Text(
            Formatters.monthYear(_month),
            style: textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _shiftMonth(-1),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
        ),
      ],
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({
    required this.total,
    required this.previousTotal,
    required this.previousMonthName,
    this.subject = 'spending',
    this.growthIsPositive = false,
  });

  final int total;
  final int previousTotal;
  final String previousMonthName;
  final String subject;

  /// Whether an increase versus the previous period is a good thing. For
  /// expenses, spending more is worse (red); for savings, more is better (green).
  final bool growthIsPositive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = AppColors.of(context);

    if (previousTotal == 0) {
      return Text(
        total == 0
            ? 'No $subject in $previousMonthName either'
            : 'No $subject recorded in $previousMonthName',
        style: textTheme.bodyMedium,
      );
    }

    final percent =
        ((total - previousTotal).abs() / previousTotal * 100).round();
    if (percent == 0) {
      return Text(
        'About the same as $previousMonthName',
        style: textTheme.bodyMedium,
      );
    }

    final isUp = total > previousTotal;
    final positiveColor = growthIsPositive ? colors.positive : colors.expense;
    final negativeColor = growthIsPositive ? colors.expense : colors.positive;
    final color = isUp ? positiveColor : negativeColor;
    return Row(
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: color,
        ),
        const SizedBox(width: Spacing.xs),
        Flexible(
          child: Text(
            '$percent% ${isUp ? 'more' : 'less'} than $previousMonthName',
            style: textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.totalMinor,
    required this.monthTotal,
    required this.currency,
  });

  final IconData icon;
  final String label;
  final int totalMinor;
  final int monthTotal;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final share = monthTotal == 0 ? 0.0 : totalMinor / monthTotal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: Sizes.glyphIcon,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(label, style: textTheme.bodyLarge),
              ),
              Text(
                currency.format(totalMinor),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: AppTypography.medium,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              const SizedBox(width: Spacing.md),
              ConstrainedBox(
                constraints:
                    const BoxConstraints(minWidth: Sizes.percentColumn),
                child: Text(
                  Formatters.percent(share),
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ProportionBar(fraction: share, fill: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _MonthHistory extends StatelessWidget {
  const _MonthHistory({
    required this.history,
    required this.selectedMonth,
    required this.currency,
  });

  final List<MonthTotal> history;
  final DateTime selectedMonth;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = AppColors.of(context);
    final largest = history.fold<int>(
      0,
      (max, month) => month.totalMinor > max ? month.totalMinor : max,
    );

    return Column(
      children: [
        for (final month in history)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: Sizes.monthLabelColumn,
                  child: Text(
                    Formatters.monthShort(month.month),
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ProportionBar(
                    fraction: largest == 0 ? 0 : month.totalMinor / largest,
                    fill: isSameMonth(month.month, selectedMonth)
                        ? theme.colorScheme.primary
                        : colors.barMuted,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 88),
                  child: Text(
                    currency.format(month.totalMinor),
                    textAlign: TextAlign.end,
                    style: textTheme.bodyMedium?.copyWith(
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
