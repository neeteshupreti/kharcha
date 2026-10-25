import 'package:expense_tracker/data/settings_repository.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(SettingsRepository repository)
      : _repository = repository,
        _themeMode = repository.readThemeMode(),
        _currency = repository.readCurrency();

  final SettingsRepository _repository;
  ThemeMode _themeMode;
  CurrencyOption _currency;

  ThemeMode get themeMode => _themeMode;
  CurrencyOption get currency => _currency;

  /// Applies the theme immediately. Resolves to false if it could not be saved.
  Future<bool> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return true;
    }
    _themeMode = mode;
    notifyListeners();
    return _repository.writeThemeMode(mode);
  }

  /// Applies the currency immediately. Resolves to false if it could not be saved.
  Future<bool> setCurrency(CurrencyOption currency) async {
    if (currency == _currency) {
      return true;
    }
    _currency = currency;
    notifyListeners();
    return _repository.writeCurrency(currency);
  }
}
