import 'package:expense_tracker/data/app_database.dart';
import 'package:expense_tracker/data/storage_exception.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed storage for expenses. Every failure surfaces as a
/// [StorageException] with a message that is safe to show to the user.
class ExpenseRepository {
  /// Whether an unexpected [Error] (not just an [Exception]) is wrapped into a
  /// [StorageException]. The database open itself is guarded elsewhere so an
  /// [Error] such as a missing factory never reaches here.
  Future<Database> get _database => AppDatabase.instance.database;

  Future<T> _guard<T>(String message, Future<T> Function() action) async {
    try {
      return await action();
    } on Exception {
      throw StorageException(message);
    }
  }

  Future<List<Expense>> fetchAll() {
    return _guard('Your expenses could not be loaded.', () async {
      final database = await _database;
      final rows =
          await database.query('expenses', orderBy: 'date DESC, id DESC');
      return rows.map(Expense.fromMap).toList();
    });
  }

  Future<Expense> insert(Expense expense) {
    return _guard('The expense could not be saved.', () async {
      final database = await _database;
      final id = await database.insert('expenses', expense.toMap());
      return expense.copyWith(id: id);
    });
  }

  Future<void> update(Expense expense) {
    return _guard('The changes could not be saved.', () async {
      final id = expense.id;
      if (id == null) {
        throw const StorageException('The changes could not be saved.');
      }
      final database = await _database;
      await database.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(int id) {
    return _guard('The expense could not be deleted.', () async {
      final database = await _database;
      await database.delete('expenses', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteAll() {
    return _guard('Your data could not be cleared.', () async {
      final database = await _database;
      await database.delete('expenses');
    });
  }
}
