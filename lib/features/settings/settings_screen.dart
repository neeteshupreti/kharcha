import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/widgets/app_snack_bar.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String _saveFailedMessage =
    'This setting could not be saved and may reset when you restart the app.';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changeTheme(BuildContext context, ThemeMode mode) async {
    final saved = await context.read<SettingsController>().setThemeMode(mode);
    if (!saved && context.mounted) {
      showAppSnackBar(context, _saveFailedMessage);
    }
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final selected = await showModalBottomSheet<CurrencyOption>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in CurrencyOption.supported)
                ListTile(
                  title: Text('${option.name} (${option.code})'),
                  trailing: option == settings.currency
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    final saved = await settings.setCurrency(selected);
    if (!saved && context.mounted) {
      showAppSnackBar(context, _saveFailedMessage);
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final expenseController = context.read<ExpenseController>();
    final savingController = context.read<SavingController>();
    final expenseCount = expenseController.totalCount;
    final savingCount = savingController.totalCount;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear all data?',
      message:
          'All $expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'} '
          'and $savingCount ${savingCount == 1 ? 'saving' : 'savings'} stored on this '
          'device will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Clear data',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final error = await expenseController.clearAll();
    final savingError = await savingController.clearAll();
    String message;
    if (error == null && savingError == null) {
      message = 'All data cleared';
    } else if (error != null && savingError != null) {
      message = '$error\n$savingError';
    } else {
      message = error ?? savingError!;
    }
    if (context.mounted) {
      showAppSnackBar(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final expenseCount = context.watch<ExpenseController>().totalCount;
    final savingCount = context.watch<SavingController>().totalCount;
    final dataCount = expenseCount + savingCount;
    final textTheme = Theme.of(context).textTheme;
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kharcha'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        children: [
          const _SectionLabel('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) =>
                  _changeTheme(context, selection.first),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const _SectionLabel('Currency'),
          _SettingsRow(
            title: settings.currency.name,
            subtitle: settings.currency.code,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCurrency(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.gutter,
              vertical: Spacing.xs,
            ),
            child: Text(
              'Changing currency only changes how amounts are shown. Existing amounts are not converted.',
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const _SectionLabel('Data'),
          _SettingsRow(
            title: 'Clear all data',
            titleColor: dataCount == 0 ? null : colors.danger,
            subtitle: dataCount == 0
                ? 'There is no data to clear'
                : 'Permanently delete every expense and saving on this device',
            onTap: dataCount == 0 ? null : () => _clearData(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              Spacing.xl,
              Spacing.gutter,
              0,
            ),
            child: Text(
              'Everything is stored on this device only. Nothing is uploaded or shared.',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.sm,
        Spacing.gutter,
        Spacing.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.gutter,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(color: titleColor),
                    ),
                    Text(subtitle, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
