import 'package:expense_tracker/core/theme/tokens.dart';
import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:expense_tracker/core/widgets/app_snack_bar.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Add a new saving entry, or edit [saving] when provided.
class SavingFormScreen extends StatefulWidget {
  const SavingFormScreen({super.key, this.saving});

  final Saving? saving;

  @override
  State<SavingFormScreen> createState() => _SavingFormScreenState();
}

class _SavingFormScreenState extends State<SavingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CurrencyOption _currency;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  SavingCategory? _category;
  late DateTime _date;
  bool _isSaving = false;

  bool get _isEditing => widget.saving != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.saving;
    _currency = context.read<SettingsController>().currency;
    _amountController = TextEditingController(
      text: existing == null ? '' : _currency.formatPlain(existing.amountMinor),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _category = existing?.category;
    _date = existing?.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: dateOnly(DateTime.now()),
    );
    if (picked != null && mounted) {
      setState(() => _date = dateOnly(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final amountMinor = Validators.parseAmount(
      _amountController.text,
      _currency.decimals,
    );
    final category = _category;
    if (amountMinor == null || category == null) {
      return;
    }
    final draft = Saving(
      id: widget.saving?.id,
      amountMinor: amountMinor,
      category: category,
      date: _date,
      note: _noteController.text.trim(),
    );
    final controller = context.read<SavingController>();

    setState(() => _isSaving = true);
    final error = _isEditing
        ? await controller.update(draft)
        : await controller.add(draft);
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() => _isSaving = false);
      showAppSnackBar(context, error);
      return;
    }
    await HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final saving = widget.saving;
    if (saving == null) {
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this saving?',
      message:
          'The ${_currency.format(saving.amountMinor)} ${saving.category.label.toLowerCase()} '
          'saving from ${Formatters.fullDate(saving.date)} will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final controller = context.read<SavingController>();
    final error = await controller.delete(saving);
    if (!mounted) {
      return;
    }
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit saving' : 'Add savings'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete saving',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : _delete,
            ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              Spacing.sm,
              Spacing.gutter,
              Spacing.xxl,
            ),
            children: [
              TextFormField(
                controller: _amountController,
                autofocus: !_isEditing,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: _currency.decimals > 0,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: textTheme.titleLarge,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: _currency.symbol,
                  hintText: _currency.decimals > 0 ? '0.00' : '0',
                ),
                validator: (value) => Validators.amount(value, _currency),
              ),
              const SizedBox(height: Spacing.xl),
              Text('Category', style: textTheme.labelMedium),
              const SizedBox(height: Spacing.sm),
              FormField<SavingCategory>(
                initialValue: _category,
                validator: (value) =>
                    value == null ? 'Choose a category' : null,
                builder: (field) {
                  return Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final category in SavingCategory.values)
                        ChoiceChip(
                          avatar: Icon(category.icon),
                          label: Text(category.label),
                          selected: field.value == category,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            field.didChange(category);
                            setState(() => _category = category);
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: Spacing.xl),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(Radii.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: Text(
                    '${Formatters.dayHeading(_date)} \u00B7 ${Formatters.fullDate(_date)}',
                    style: textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              TextFormField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                maxLength: Validators.maxNoteLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Save savings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
