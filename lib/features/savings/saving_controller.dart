import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/data/saving_repository.dart';
import 'package:expense_tracker/data/storage_exception.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:expense_tracker/models/saving_filter.dart';
import 'package:expense_tracker/models/summaries.dart';
import 'package:flutter/foundation.dart';

/// Holds all savings entries in memory (a personal ledger is small) and keeps
/// the database in step. Mirrors [ExpenseController] but for the [Saving]
/// ledger.
class SavingController extends ChangeNotifier {
  SavingController(this._repository);

  final SavingRepository _repository;

  List<Saving> _savings = const [];
  SavingFilter _filter = const SavingFilter();
  bool _isLoading = true;
  String? _loadError;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  SavingFilter get filter => _filter;
  int get totalCount => _savings.length;

  /// Savings matching the active filter, newest first.
  List<Saving> get visibleSavings {
    if (!_filter.isActive) {
      return _savings;
    }
    return _savings.where(_filter.matches).toList();
  }

  Future<void> load() async {
    if (!_isLoading) {
      _isLoading = true;
      _loadError = null;
      notifyListeners();
    }
    try {
      _savings = _sorted(await _repository.fetchAll());
    } on StorageException catch (error) {
      _loadError = error.message;
    } catch (_) {
      // Catch any non-Exception (e.g. StateError from an unconfigured database)
      // so loading always resolves instead of leaving the UI on a spinner.
      _loadError = 'Your savings could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(SavingFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<String?> add(Saving saving) async {
    try {
      final saved = await _repository.insert(saving);
      _savings = _sorted([..._savings, saved]);
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<String?> update(Saving saving) async {
    try {
      await _repository.update(saving);
      _savings = _sorted([
        for (final existing in _savings)
          if (existing.id == saving.id) saving else existing,
      ]);
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<String?> delete(Saving saving) async {
    final id = saving.id;
    if (id == null) {
      return 'The saving could not be deleted.';
    }
    try {
      await _repository.delete(id);
      _savings = [
        for (final existing in _savings)
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
      _savings = const [];
      _filter = const SavingFilter();
      notifyListeners();
      return null;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  // Summaries -----------------------------------------------------------

  int totalForMonth(DateTime month) {
    var total = 0;
    for (final saving in _savings) {
      if (isSameMonth(saving.date, month)) {
        total += saving.amountMinor;
      }
    }
    return total;
  }

  int countForMonth(DateTime month) {
    return _savings.where((s) => isSameMonth(s.date, month)).length;
  }

  /// Category totals for [month], largest first.
  List<SavingCategoryTotal> categoryTotals(DateTime month) {
    final totals = <SavingCategory, int>{};
    for (final saving in _savings) {
      if (isSameMonth(saving.date, month)) {
        totals.update(
          saving.category,
          (value) => value + saving.amountMinor,
          ifAbsent: () => saving.amountMinor,
        );
      }
    }
    return [
      for (final entry in totals.entries)
        SavingCategoryTotal(category: entry.key, totalMinor: entry.value),
    ]..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
  }

  // Range-based summaries --------------------------------------------------

  /// Total amount for savings within the given date range (inclusive).
  int totalForRange(DateTime start, DateTime end) {
    var total = 0;
    for (final saving in _savings) {
      if (!saving.date.isBefore(start) && !saving.date.isAfter(end)) {
        total += saving.amountMinor;
      }
    }
    return total;
  }

  /// Count of savings within the given date range (inclusive).
  int countForRange(DateTime start, DateTime end) {
    return _savings
        .where((s) => !s.date.isBefore(start) && !s.date.isAfter(end))
        .length;
  }

  /// Category totals for the given date range, largest first.
  List<SavingCategoryTotal> categoryTotalsForRange(
    DateTime start,
    DateTime end,
  ) {
    final totals = <SavingCategory, int>{};
    for (final saving in _savings) {
      if (!saving.date.isBefore(start) && !saving.date.isAfter(end)) {
        totals.update(
          saving.category,
          (value) => value + saving.amountMinor,
          ifAbsent: () => saving.amountMinor,
        );
      }
    }
    return [
      for (final entry in totals.entries)
        SavingCategoryTotal(category: entry.key, totalMinor: entry.value),
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

  static List<Saving> _sorted(List<Saving> savings) {
    return [...savings]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
      });
  }
}
