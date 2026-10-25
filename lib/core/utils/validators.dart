import 'package:expense_tracker/models/currency_option.dart';

abstract final class Validators {
  static const int maxNoteLength = 120;

  /// Returns an inline error message, or null when [value] is a valid amount.
  static String? amount(String? value, CurrencyOption currency) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Enter an amount';
    }
    final minor = parseAmount(text, currency.decimals);
    if (minor == null) {
      return currency.decimals == 0
          ? 'Use whole numbers only, for example 1200'
          : 'Use a number such as 12.50';
    }
    if (minor <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  /// Converts user input such as "12.5" or "12,50" to minor units (1250).
  /// Returns null when the text is not a valid amount for [decimals].
  static int? parseAmount(String? value, int decimals) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    final pattern = decimals == 0
        ? RegExp(r'^\d{1,9}$')
        : RegExp('^\\d{1,9}(\\.\\d{1,$decimals})?\$');
    if (!pattern.hasMatch(text)) {
      return null;
    }
    final parts = text.split('.');
    final whole = int.parse(parts.first);
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    if (decimals == 0) {
      return whole;
    }
    final fraction = parts.length > 1 ? parts[1].padRight(decimals, '0') : '0';
    return whole * scale + int.parse(fraction);
  }
}
