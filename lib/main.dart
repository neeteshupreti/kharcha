import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/core/db/sqflite_factory.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/saving_repository.dart';
import 'package:expense_tracker/data/settings_repository.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must run before any repository tries to open a database. On desktop and
  // the web `sqflite` ships no factory of its own, so without this the global
  // factory throws and the home screen stays on its loading spinner forever.
  initializeDatabaseFactory();
  final settingsRepository = await SettingsRepository.create();
  runApp(
    ExpenseApp(
      settingsRepository: settingsRepository,
      expenseRepository: ExpenseRepository(),
      savingRepository: SavingRepository(),
    ),
  );
}
