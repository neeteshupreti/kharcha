import 'package:expense_tracker/models/currency_option.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Persists small user preferences. If preferences cannot be opened, the app
/// keeps working with defaults and reports failed writes to the caller.
class SettingsRepository {
  SettingsRepository._(this._preferences);

  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'currency_code';

  final SharedPreferences? _preferences;

  static Future<SettingsRepository> create() async {
    try {
      return SettingsRepository._(await SharedPreferences.getInstance());
    } on Exception {
      return SettingsRepository._(null);
    }
  }

  ThemeMode readThemeMode() {
    final stored = _preferences?.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  CurrencyOption readCurrency() {
    return CurrencyOption.byCode(_preferences?.getString(_currencyKey));
  }

  Future<bool> writeThemeMode(ThemeMode mode) => _write(_themeKey, mode.name);

  Future<bool> writeCurrency(CurrencyOption currency) {
    return _write(_currencyKey, currency.code);
  }

  Future<bool> _write(String key, String value) async {
    try {
      return await _preferences?.setString(key, value) ?? false;
    } on Exception {
      return false;
    }
  }
}
