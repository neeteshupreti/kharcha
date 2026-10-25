import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart';

@immutable
class ExpenseFilter {
  const ExpenseFilter({this.range, this.category});

  /// Inclusive range of calendar days.
  final DateTimeRange? range;
  final ExpenseCategory? category;

  bool get isActive => range != null || category != null;

  int get activeCount => (range != null ? 1 : 0) + (category != null ? 1 : 0);

  ExpenseFilter copyWith({
    DateTimeRange? range,
    ExpenseCategory? category,
    bool clearRange = false,
    bool clearCategory = false,
  }) {
    return ExpenseFilter(
      range: clearRange ? null : (range ?? this.range),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  bool matches(Expense expense) {
    final selectedRange = range;
    if (selectedRange != null &&
        (expense.date.isBefore(selectedRange.start) ||
            expense.date.isAfter(selectedRange.end))) {
      return false;
    }
    final selectedCategory = category;
    return selectedCategory == null || expense.category == selectedCategory;
  }
}
