import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:flutter/foundation.dart';

@immutable
class CategoryTotal {
  const CategoryTotal({required this.category, required this.totalMinor});

  final ExpenseCategory category;
  final int totalMinor;
}

@immutable
class SavingCategoryTotal {
  const SavingCategoryTotal({required this.category, required this.totalMinor});

  final SavingCategory category;
  final int totalMinor;
}

@immutable
class MonthTotal {
  const MonthTotal({required this.month, required this.totalMinor});

  final DateTime month;
  final int totalMinor;
}
