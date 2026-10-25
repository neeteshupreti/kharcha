import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/storage_exception.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_filter.dart';
import 'package:expense_tracker/models/summaries.dart';
import 'package:flutter/foundation.dart';

/// Holds all expenses in memory (a personal ledger is small) and keeps the
/// database in step. Mutations resolve to an error message, or null on success.
class ExpenseController extends ChangeNotifier {
  ExpenseController(this._repository);

  final ExpenseRepository _repository;

  List<Expense> _expenses = const [];
  ExpenseFilter _filter = const ExpenseFilter();
  bool _isLoading = true;
  String? _loadError;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  ExpenseFilter get filter => _filter;
  int get totalCount => _expenses.length;

  /// Expenses matching the active filter, newest first.
  List<Expense> get visibleExpenses {
    if (!_filter.isActive) {
      return _expenses;
    }
    return _expenses.where(_filter.matches).toList();
  }

  Future<void> load() async {
    if (!_isLoading) {
      _isLoading = true;
      _loadError = null;
      notifyListeners();
    }
    try {
      _expenses = _sorted(await _repository.fetchAll());
    } on StorageException catch (error) {
      _loadError = error.message;
    } catch (_) {
      // Catch any non-Exception (e.g. StateError from an unconfigured database)
      // so loading always resolves instead of leaving the UI on a spinner.
      _loadError = 'Your expenses could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(ExpenseFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<String?> add(Expense expense) async {
    try {
      final saved = await _repository.insert(expense);
      _expenses = _sorted([..._expenses, saved]);
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<String?> update(Expense expense) async {
    try {
      await _repository.update(expense);
      _expenses = _sorted([
        for (final existing in _expenses)
          if (existing.id == expense.id) expense else existing,
      ]);
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<String?> delete(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      return 'The expense could not be deleted.';
    }
    try {
      await _repository.delete(id);
      _expenses = [
        for (final existing in _expenses)
          if (existing.id != id) existing,
      ];
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<String?> clearAll() async {
    try {
      await _repository.deleteAll();
      _expenses = const [];
      _filter = const ExpenseFilter();
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  // Summaries -----------------------------------------------------------

  int totalForMonth(DateTime month) {
    var total = 0;
    for (final expense in _expenses) {
      if (isSameMonth(expense.date, month)) {
        total += expense.amountMinor;
      }
    }
    return total;
  }

  int countForMonth(DateTime month) {
    return _expenses.where((e) => isSameMonth(e.date, month)).length;
  }

  /// Category totals for [month], largest first.
  List<CategoryTotal> categoryTotals(DateTime month) {
    final totals = <ExpenseCategory, int>{};
    for (final expense in _expenses) {
      if (isSameMonth(expense.date, month)) {
        totals.update(
          expense.category,
          (value) => value + expense.amountMinor,
          ifAbsent: () => expense.amountMinor,
        );
      }
    }
    return [
      for (final entry in totals.entries)
        CategoryTotal(category: entry.key, totalMinor: entry.value),
    ]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
  }

  /// Totals for the [count] months ending with [endMonth], oldest first.
  List<MonthTotal> monthlyTotals(DateTime endMonth, {int count = 6}) {
    final last = monthStart(endMonth);
    return [
      for (var offset = count - 1; offset >= 0; offset--)
        MonthTotal(
          month: addMonths(last, -offset),
          totalMinor: totalForMonth(addMonths(last, -offset)),
        ),
    ];
  }

  // Range-based summaries --------------------------------------------------

  /// Total amount for expenses within the given date range (inclusive).
  int totalForRange(DateTime start, DateTime end) {
    var total = 0;
    for (final expense in _expenses) {
      if (!expense.date.isBefore(start) && !expense.date.isAfter(end)) {
        total += expense.amountMinor;
      }
    }
    return total;
  }

  /// Count of expenses within the given date range (inclusive).
  int countForRange(DateTime start, DateTime end) {
    return _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .length;
  }

  /// Category totals for the given date range, largest first.
  List<CategoryTotal> categoryTotalsForRange(DateTime start, DateTime end) {
    final totals = <ExpenseCategory, int>{};
    for (final expense in _expenses) {
      if (!expense.date.isBefore(start) && !expense.date.isAfter(end)) {
        totals.update(
          expense.category,
          (value) => value + expense.amountMinor,
          ifAbsent: () => expense.amountMinor,
        );
      }
    }
    return [
      for (final entry in totals.entries)
        CategoryTotal(category: entry.key, totalMinor: entry.value),
    ]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
  }

  static List<Expense> _sorted(List<Expense> expenses) {
    return [...expenses]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
      });
  }
}
