import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/saving_repository.dart';
import 'package:expense_tracker/data/settings_repository.dart';
import 'package:expense_tracker/features/expenses/expense_controller.dart';
import 'package:expense_tracker/features/savings/saving_controller.dart';
import 'package:expense_tracker/features/settings/settings_controller.dart';
import 'package:expense_tracker/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({
    super.key,
    required this.settingsRepository,
    required this.expenseRepository,
    required this.savingRepository,
  });

  final SettingsRepository settingsRepository;
  final ExpenseRepository expenseRepository;
  final SavingRepository savingRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController(settingsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseController(expenseRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingController(savingRepository)..load(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsController, ThemeMode>(
      (settings) => settings.themeMode,
    );
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      home: const AppShell(),
    );
  }
}
