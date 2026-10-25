import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:expense_tracker/core/widgets/empty_state.dart';
import 'package:expense_tracker/features/expenses/expense_list_items.dart';
import 'package:expense_tracker/features/savings/saving_form_screen.dart';
import 'package:expense_tracker/features/savings/saving_list_items.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/savings/saving_filter_sheet.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/core/widgets/transactions_header.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:expense_tracker/models/saving_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lists savings entries, grouped by day, mirroring the expenses screen.
/// Supports the same category + date-range filters.
class SavingListScreen extends StatelessWidget {
  const SavingListScreen({super.key});

  void _openForm(BuildContext context, {Saving? saving}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: saving == null,
        builder: (_) => SavingFormScreen(saving: saving),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    SavingController controller,
  ) async {
    final result = await showSavingFilterSheet(context, controller.filter);
    if (result != null) {
      controller.setFilter(result);
    }
  }

  Future<void> _remove(
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
    final controller = context.watch<SavingController>();
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
        icon: const Icon(Icons.savings),
        label: const Text('Add savings'),
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
                title: 'Savings',
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
    SavingController controller,
    CurrencyOption currency,
  ) {
    if (controller.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              semanticsLabel: 'Loading savings',
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
            title: 'Could not load savings',
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
              icon: Icons.savings_outlined,
              title: 'No savings yet',
              message:
                  'Tap "Add savings" to record your first one, grouped by day.',
            ),
          ),
        ),
      ];
    }

    final visible = controller.visibleSavings;
    if (visible.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.filter_list_off,
            title: 'No matching savings',
            message: 'Nothing fits the current filters.',
            action: TextButton(
              onPressed: () => controller.setFilter(const SavingFilter()),
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
              _SavingRow(:final saving) => SavingTile(
                  saving: saving,
                  currency: currency,
                  onTap: () => _openForm(context, saving: saving),
                  onDelete: () => _remove(context, controller, saving),
                ),
            };
          },
        ),
      ),
    ];
  }

  static List<_ListRow> _groupByDay(List<Saving> savings) {
    final dayTotals = <DateTime, int>{};
    for (final saving in savings) {
      dayTotals.update(
        saving.date,
        (value) => value + saving.amountMinor,
        ifAbsent: () => saving.amountMinor,
      );
    }
    final rows = <_ListRow>[];
    DateTime? lastDay;
    for (final saving in savings) {
      if (lastDay != saving.date) {
        rows.add(_DayHeaderRow(saving.date, dayTotals[saving.date]!));
        lastDay = saving.date;
      }
      rows.add(_SavingRow(saving));
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

final class _SavingRow extends _ListRow {
  const _SavingRow(this.saving);
  final Saving saving;
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
        ? 'Nothing saved yet this month'
        : '$count ${count == 1 ? 'entry' : 'entries'}';

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
            'Saved in ${Formatters.monthName(month)}',
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
