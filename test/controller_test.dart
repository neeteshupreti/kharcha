import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/saving_repository.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [ExpenseRepository] that either returns no rows or throws an
/// [Error] (not an [Exception]) — mirroring the real `StateError` that the
/// unconfigured sqflite factory used to throw.
class _FakeExpenseRepo extends ExpenseRepository {
  _FakeExpenseRepo({this.throwError = false});

  final bool throwError;

  @override
  Future<List<Expense>> fetchAll() => throwError
      ? Future.error(StateError('databaseFactory not initialized'))
      : Future.value(<Expense>[]);
}

class _FakeSavingRepo extends SavingRepository {
  _FakeSavingRepo({this.throwError = false});

  final bool throwError;

  @override
  Future<List<Saving>> fetchAll() => throwError
      ? Future.error(StateError('databaseFactory not initialized'))
      : Future.value(<Saving>[]);
}

void main() {
  test('ExpenseController resolves loading instead of spinning forever',
      () async {
    final controller = ExpenseController(_FakeExpenseRepo(throwError: true));
    await controller.load();
    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNotNull);
    expect(controller.totalCount, 0);
  });

  test('ExpenseController loads an empty ledger', () async {
    final controller = ExpenseController(_FakeExpenseRepo());
    await controller.load();
    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNull);
    expect(controller.totalCount, 0);
  });

  test('SavingController resolves loading instead of spinning forever',
      () async {
    final controller = SavingController(_FakeSavingRepo(throwError: true));
    await controller.load();
    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNotNull);
    expect(controller.totalCount, 0);
  });
}
