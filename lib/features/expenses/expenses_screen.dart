import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:expense_tracker/core/widgets/empty_state.dart';
import 'package:expense_tracker/core/widgets/transactions_header.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/expenses/expense_form_screen.dart';
import 'package:expense_tracker/features/expenses/expense_list_items.dart';
import 'package:expense_tracker/features/expenses/filter_sheet.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The expenses-only tab. Shows every expense (newest first) with a month
/// summary and filter bar, and lets you add, edit, or delete each entry. The
/// dashboard and this list both read from [ExpenseController], so totals stay
/// in sync automatically.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _openForm(BuildContext context, {Expense? expense}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: expense == null,
        builder: (_) => ExpenseFormScreen(expense: expense),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    ExpenseController controller,
  ) async {
    final result = await showExpenseFilterSheet(context, controller.filter);
    if (result != null) {
      controller.setFilter(result);
    }
  }

  Future<void> _remove(
    BuildContext context,
    ExpenseController controller,
    Expense expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final currency = context.read<SettingsController>().currency;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this expense?',
      message: 'The ${currency.format(expense.amountMinor)} '
          '${expense.category.label.toLowerCase()} expense from '
          '${Formatters.fullDate(expense.date)} will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final error = await controller.delete(expense);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();
    final currency = context.watch<SettingsController>().currency;
    final now = DateTime.now();
    final monthTotal = controller.totalForMonth(now);
    final monthCount = controller.countForMonth(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kharcha'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: CustomScrollView(
        slivers: [
          if (controller.totalCount > 0)
            SliverToBoxAdapter(
              child: _MonthSummary(
                month: now,
                total: currency.format(monthTotal),
                count: monthCount,
              ),
            ),
          if (controller.totalCount > 0)
            SliverToBoxAdapter(
              child: TransactionsHeader(
                title: 'Transactions',
                filterIsActive: controller.filter.isActive,
                activeCount: controller.filter.activeCount,
                rangeText: controller.filter.range == null
                    ? null
                    : Formatters.rangeLabel(controller.filter.range!),
                categoryText: controller.filter.category?.label,
                onOpenFilters: () => _openFilters(context, controller),
                onClearRange: () => controller.setFilter(
                  controller.filter.copyWith(clearRange: true),
                ),
                onClearCategory: () => controller.setFilter(
                  controller.filter.copyWith(clearCategory: true),
                ),
              ),
            ),
          ..._buildContent(context, controller, currency),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    ExpenseController controller,
    CurrencyOption currency,
  ) {
    if (controller.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              semanticsLabel: 'Loading expenses',
            ),
          ),
        ),
      ];
    }

    final loadError = controller.loadError;
    if (loadError != null) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load expenses',
            message: loadError,
            action: FilledButton(
              onPressed: controller.load,
              child: const Text('Try again'),
            ),
          ),
        ),
      ];
    }

    if (controller.totalCount == 0) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: Spacing.xxl),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message: 'Tap "Add expense" to record your first one.',
            ),
          ),
        ),
      ];
    }

    final visible = controller.visibleExpenses;
    if (visible.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.filter_list_off,
            title: 'No matching expenses',
            message: 'Nothing fits the current filters.',
            action: TextButton(
              onPressed: () => controller.setFilter(const ExpenseFilter()),
              child: const Text('Clear filters'),
            ),
          ),
        ),
      ];
    }

    final rows = _groupByDay(visible);
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 96),
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            return switch (rows[index]) {
              _DayHeaderRow(:final date, :final totalMinor) => DayHeading(
                  date: date,
                  total: currency.format(totalMinor),
                ),
              _ExpenseRow(:final expense) => ExpenseTile(
                  expense: expense,
                  currency: currency,
                  onTap: () => _openForm(context, expense: expense),
                  onDelete: () => _remove(context, controller, expense),
                ),
            };
          },
        ),
      ),
    ];
  }

  static List<_ListRow> _groupByDay(List<Expense> expenses) {
    final dayTotals = <DateTime, int>{};
    for (final expense in expenses) {
      dayTotals.update(
        expense.date,
        (value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }
    final rows = <_ListRow>[];
    DateTime? lastDay;
    for (final expense in expenses) {
      if (lastDay != expense.date) {
        rows.add(_DayHeaderRow(expense.date, dayTotals[expense.date]!));
        lastDay = expense.date;
      }
      rows.add(_ExpenseRow(expense));
    }
    return rows;
  }
}

sealed class _ListRow {
  const _ListRow();
}

final class _DayHeaderRow extends _ListRow {
  const _DayHeaderRow(this.date, this.totalMinor);

  final DateTime date;
  final int totalMinor;
}

final class _ExpenseRow extends _ListRow {
  const _ExpenseRow(this.expense);

  final Expense expense;
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.month,
    required this.total,
    required this.count,
  });

  final DateTime month;
  final String total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = count == 0
        ? 'Nothing recorded yet this month'
        : '$count ${count == 1 ? 'transaction' : 'transactions'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.sm,
        Spacing.gutter,
        Spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent in ${Formatters.monthName(month)}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(total, style: textTheme.displaySmall),
          ),
          const SizedBox(height: Spacing.xs),
          Text(detail, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
