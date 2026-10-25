import 'package:expense_tracker/core/db/sqflite_factory.dart';
import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/data/app_database.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/saving_repository.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the desktop storage path actually works end-to-end on Linux:
/// installing the FFI factory (with the sqlite3 library override) lets the
/// database open, the `expenses` and `savings` tables coexist, and rows
/// round-trip. This is what unblocks the home screen loading instead of
/// buffering forever.
void main() {
  setUp(() async {
    initializeDatabaseFactory();
    await ExpenseRepository().deleteAll();
    await SavingRepository().deleteAll();
  });

  tearDown(() async {
    await ExpenseRepository().deleteAll();
    await SavingRepository().deleteAll();
    await AppDatabase.instance.close();
  });

  test('FFI database opens and round-trips expenses and savings', () async {
    final expenseRepo = ExpenseRepository();
    final savingRepo = SavingRepository();

    final today = dateOnly(DateTime(2026, 9, 5));
    final expense = await expenseRepo.insert(Expense(
      amountMinor: 125000,
      category: ExpenseCategory.food,
      date: today,
      note: 'Test expense',
    ));
    final saving = await savingRepo.insert(Saving(
      amountMinor: 50000,
      category: SavingCategory.values.firstWhere((c) => c.name == 'piggyBank'),
      date: today,
      note: 'Test saving',
    ));

    expect(expense.id, isNotNull);
    expect(saving.id, isNotNull);
    expect((await expenseRepo.fetchAll()).length, 1);
    expect((await savingRepo.fetchAll()).length, 1);
  });
}
