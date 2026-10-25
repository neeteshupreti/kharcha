import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimals = 2,
  });

  final String code;
  final String symbol;
  final String name;
  final int decimals;

  static final Map<String, NumberFormat> _numberFormats = {};

  static const List<CurrencyOption> supported = [
    CurrencyOption(code: 'NPR', symbol: 'रु ', name: 'Nepalese rupee'),
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US dollar'),
    CurrencyOption(code: 'EUR', symbol: '\u20AC', name: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '\u00A3', name: 'British pound'),
    CurrencyOption(
        code: 'JPY', symbol: '\u00A5', name: 'Japanese yen', decimals: 0),
    CurrencyOption(code: 'INR', symbol: '\u20B9', name: 'Indian rupee'),
    CurrencyOption(code: 'CAD', symbol: 'CA\$', name: 'Canadian dollar'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian dollar'),
    CurrencyOption(code: 'CHF', symbol: 'CHF ', name: 'Swiss franc'),
  ];

  static CurrencyOption byCode(String? code) {
    return supported.firstWhere(
      (option) => option.code == code,
      orElse: () => supported.first,
    );
  }

  double _toMajor(int minor) {
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    return minor / scale;
  }

  /// Display string with symbol and grouping, for example "$1,250.00".
  ///
  /// The symbol is prepended verbatim, so currencies whose symbol already
  /// carries their own trailing space (e.g. NPR "रु ") always render with a
  /// space before the number ("रु 1,250.00") regardless of the locale's
  /// currency placement pattern.
  String format(int minor) {
    final number = _formatNumber(minor);
    return '$symbol$number';
  }

  /// Grouped, locale-aware number with the right amount of decimals, but no
  /// symbol. Cached per currency so we don't rebuild the formatter every call.
  String _formatNumber(int minor) {
    final formatter = _numberFormats.putIfAbsent(
      code,
      () => NumberFormat.decimalPatternDigits(decimalDigits: decimals),
    );
    return formatter.format(_toMajor(minor));
  }

  /// Plain number without symbol or grouping, used to prefill the edit form.
  String formatPlain(int minor) => _toMajor(minor).toStringAsFixed(decimals);

  @override
  bool operator ==(Object other) =>
      other is CurrencyOption && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
