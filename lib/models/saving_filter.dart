import 'package:expense_tracker/models/saving.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Filter for the savings ledger, mirroring [ExpenseFilter].
@immutable
class SavingFilter {
  const SavingFilter({this.range, this.category});

  /// Inclusive range of calendar days.
  final DateTimeRange? range;
  final SavingCategory? category;

  bool get isActive => range != null || category != null;

  int get activeCount => (range != null ? 1 : 0) + (category != null ? 1 : 0);

  SavingFilter copyWith({
    DateTimeRange? range,
    SavingCategory? category,
    bool clearRange = false,
    bool clearCategory = false,
  }) {
    return SavingFilter(
      range: clearRange ? null : (range ?? this.range),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  bool matches(Saving saving) {
    final selectedRange = range;
    if (selectedRange != null &&
        (saving.date.isBefore(selectedRange.start) ||
            saving.date.isAfter(selectedRange.end))) {
      return false;
    }
    final selectedCategory = category;
    // [SavingCategory] equality is by name, so this compares categories safely.
    return selectedCategory == null || saving.category == selectedCategory;
  }
}
