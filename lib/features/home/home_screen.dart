import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:expense_tracker/core/widgets/empty_state.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/expenses/expense_form_screen.dart';
import 'package:expense_tracker/features/expenses/expense_list_items.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/savings/saving_form_screen.dart';
import 'package:expense_tracker/features/savings/saving_list_items.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The dashboard home. Unlike the expenses-only and savings-only tabs, this
/// screen blends every ledger entry into a single newest-first timeline, with a
/// running month summary that recomputes the moment any entry is edited or
/// removed (the underlying [ExpenseController] / [SavingController] notify and
/// the [Row]s below rebuild instantly).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openExpenseForm(BuildContext context, {Expense? expense}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: expense == null,
        builder: (_) => ExpenseFormScreen(expense: expense),
      ),
    );
  }

  void _openSavingForm(BuildContext context, {Saving? saving}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: saving == null,
        builder: (_) => SavingFormScreen(saving: saving),
      ),
    );
  }

  Future<void> _showAddChoice(BuildContext context) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              title: const Text('Add expense'),
              onTap: () {
                Navigator.of(context).pop();
                _openExpenseForm(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.savings_outlined),
              ),
              title: const Text('Add saving'),
              onTap: () {
                Navigator.of(context).pop();
                _openSavingForm(context);
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _removeExpense(
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

  Future<void> _removeSaving(
    BuildContext context,
    SavingController controller,
    Saving saving,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final currency = context.read<SettingsController>().currency;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this saving?',
      message: 'The ${currency.format(saving.amountMinor)} '
          '${saving.category.label.toLowerCase()} saving from '
          '${Formatters.fullDate(saving.date)} will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final error = await controller.delete(saving);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final savingController = context.watch<SavingController>();
    final currency = context.watch<SettingsController>().currency;
    final now = DateTime.now();

    final loading = expenseController.isLoading || savingController.isLoading;
    final error = expenseController.loadError ?? savingController.loadError;
    final expenseCount = expenseController.totalCount;
    final savingCount = savingController.totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kharcha'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => _showAddChoice(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Builder(
              builder: (_) {
                if (error != null) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load data',
                      message: error,
                      action: FilledButton(
                        onPressed: () {
                          expenseController.load();
                          savingController.load();
                        },
                        child: const Text('Try again'),
                      ),
                    ),
                  );
                }
                if (expenseCount == 0 && savingCount == 0) {
                  return const _EmptyOverview();
                }
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _MonthSummaryCard(
                        month: now,
                        spent: currency
                            .format(expenseController.totalForMonth(now)),
                        saved: currency
                            .format(savingController.totalForMonth(now)),
                        netMinor: savingController.totalForMonth(now) -
                            expenseController.totalForMonth(now),
                        currency: currency,
                      ),
                    ),
                    const SliverToBoxAdapter(child: _TransactionsHeader()),
                    ..._buildTimeline(
                        expenseController, savingController, currency),
                  ],
                );
              },
            ),
    );
  }

  List<Widget> _buildTimeline(
    ExpenseController expenseController,
    SavingController savingController,
    CurrencyOption currency,
  ) {
    final entries = _mergeEntries(expenseController, savingController);
    if (entries.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: Spacing.xxl),
            child: EmptyState(
              icon: Icons.search_off_outlined,
              title: 'No transactions yet',
              message: 'Expenses and savings you add from the tabs below will '
                  'appear here, newest first.',
            ),
          ),
        ),
      ];
    }

    final rows = _groupByDay(entries);
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 96),
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            switch (row) {
              case _DayHeaderRow(date: final date, netMinor: final net):
                return DayHeading(
                  date: date,
                  total: _signedAmount(net, currency),
                );
              case _ExpenseRow(expense: final expense):
                return ExpenseTile(
                  expense: expense,
                  currency: currency,
                  onTap: () => _openExpenseForm(context, expense: expense),
                  onDelete: () =>
                      _removeExpense(context, expenseController, expense),
                );
              case _SavingRow(saving: final saving):
                return SavingTile(
                  saving: saving,
                  currency: currency,
                  onTap: () => _openSavingForm(context, saving: saving),
                  onDelete: () =>
                      _removeSaving(context, savingController, saving),
                );
            }
          },
        ),
      ),
    ];
  }
}

String _signedAmount(int minor, CurrencyOption currency) {
  final sign = minor >= 0 ? '+' : '−';
  return '$sign${currency.formatPlain(minor.abs())}';
}

/// An item in the dashboard timeline — either an expense or a saving.
final class _Entry {
  const _Entry({
    required this.date,
    required this.signed,
    required this.id,
    this.expense,
    this.saving,
  });

  factory _Entry.expense(Expense expense) => _Entry(
        date: expense.date,
        signed: -expense.amountMinor,
        id: expense.id ?? 0,
        expense: expense,
      );

  factory _Entry.saving(Saving saving) => _Entry(
        date: saving.date,
        signed: saving.amountMinor,
        id: saving.id ?? 0,
        saving: saving,
      );

  final DateTime date;
  final int signed;
  final int id;
  final Expense? expense;
  final Saving? saving;
}

List<_Entry> _mergeEntries(
  ExpenseController expenseController,
  SavingController savingController,
) {
  final entries = [
    for (final e in expenseController.visibleExpenses) _Entry.expense(e),
    for (final s in savingController.visibleSavings) _Entry.saving(s),
  ];
  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) {
      return byDate;
    }
    return b.id.compareTo(a.id);
  });
  return entries;
}

sealed class _Row {
  const _Row();
}

final class _DayHeaderRow extends _Row {
  const _DayHeaderRow(this.date, this.netMinor);

  final DateTime date;
  final int netMinor;
}

final class _ExpenseRow extends _Row {
  const _ExpenseRow(this.expense);

  final Expense expense;
}

final class _SavingRow extends _Row {
  const _SavingRow(this.saving);

  final Saving saving;
}

List<_Row> _groupByDay(List<_Entry> entries) {
  final dayNets = <DateTime, int>{};
  for (final entry in entries) {
    dayNets.update(
      entry.date,
      (value) => value + entry.signed,
      ifAbsent: () => entry.signed,
    );
  }

  final rows = <_Row>[];
  DateTime? lastDay;
  for (final entry in entries) {
    if (lastDay != entry.date) {
      rows.add(_DayHeaderRow(entry.date, dayNets[entry.date]!));
      lastDay = entry.date;
    }
    if (entry.expense != null) {
      rows.add(_ExpenseRow(entry.expense!));
    } else if (entry.saving != null) {
      rows.add(_SavingRow(entry.saving!));
    }
  }
  return rows;
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.gutter,
        right: Spacing.gutter,
        bottom: Spacing.xs,
      ),
      child: Text('All transactions', style: textTheme.titleMedium),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.month,
    required this.spent,
    required this.saved,
    required this.netMinor,
    required this.currency,
  });

  final DateTime month;
  final String spent;
  final String saved;
  final int netMinor;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final netStyle = TextStyle(
      color:
          netMinor >= 0 ? theme.colorScheme.tertiary : theme.colorScheme.error,
      fontWeight: AppTypography.semibold,
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.sm,
        Spacing.gutter,
        Spacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month · ${Formatters.monthName(month)}',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              spent,
              style: textTheme.headlineSmall,
            ),
            Text('Spent', style: textTheme.bodySmall),
            const SizedBox(height: Spacing.sm),
            Text(
              saved,
              style: textTheme.headlineSmall,
            ),
            Text('Saved', style: textTheme.bodySmall),
            const SizedBox(height: Spacing.sm),
            Text(
              _signedAmount(netMinor, currency),
              style: textTheme.headlineSmall?.copyWith(
                color: netStyle.color,
              ),
            ),
            Text(
              netMinor >= 0 ? 'Net saved' : 'Net spent',
              style: textTheme.bodySmall?.copyWith(color: netStyle.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOverview extends StatelessWidget {
  const _EmptyOverview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'All clear',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Expenses and savings appear here once you add them. '
            'Use the tabs below to record transactions.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
