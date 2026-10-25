import 'package:expense_tracker/data/app_database.dart';
import 'package:expense_tracker/data/storage_exception.dart';
import 'package:expense_tracker/models/saving.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed storage for savings. Every failure surfaces as a
/// [StorageException] with a message that is safe to show to the user.
class SavingRepository {
  Future<Database> get _database => AppDatabase.instance.database;

  Future<T> _guard<T>(String message, Future<T> Function() action) async {
    try {
      return await action();
    } on Exception {
      throw StorageException(message);
    }
  }

  Future<List<Saving>> fetchAll() {
    return _guard('Your savings could not be loaded.', () async {
      final database = await _database;
      final rows =
          await database.query('savings', orderBy: 'date DESC, id DESC');
      return rows.map(Saving.fromMap).toList();
    });
  }

  Future<Saving> insert(Saving saving) {
    return _guard('The saving could not be saved.', () async {
      final database = await _database;
      final id = await database.insert('savings', saving.toMap());
      return saving.copyWith(id: id);
    });
  }

  Future<void> update(Saving saving) {
    return _guard('The changes could not be saved.', () async {
      final id = saving.id;
      if (id == null) {
        throw const StorageException('The changes could not be saved.');
      }
      final database = await _database;
      await database.update(
        'savings',
        saving.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(int id) {
    return _guard('The saving could not be deleted.', () async {
      final database = await _database;
      await database.delete('savings', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteAll() {
    return _guard('Your data could not be cleared.', () async {
      final database = await _database;
      await database.delete('savings');
    });
  }
}
