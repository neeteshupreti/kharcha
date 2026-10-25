import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single source of truth for opening the app's SQLite file.
///
/// Both the expense and saving repositories open the same `expenses.db` file,
/// so the version, schema and migrations must be owned by one place. Opening
/// the file from two repositories with different versions caused sqflite to
/// treat the second open as a database downgrade and throw, breaking saves.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'expenses.db';

  /// Bumped to 2 when the `savings` table was added. Existing databases that
  /// were created at version 1 (expenses only) are migrated in [_upgrade].
  static const int version = 2;

  Database? _database;

  Future<Database> get database async {
    final cached = _database;
    if (cached != null) {
      return cached;
    }
    final database = await _open();
    _database = database;
    return database;
  }

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, databaseName),
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
    await db.execute('''
      CREATE TABLE savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_savings_date ON savings (date)');
  }

  /// Adds the `savings` table to databases created by the previous version.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_savings_date ON savings (date)');
    }
  }

  /// Closes the database, mainly useful in tests.
  Future<void> close() => _database?.close() ?? Future.value();
}
