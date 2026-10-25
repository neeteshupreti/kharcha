import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:expense_tracker/models/currency_option.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const usd = CurrencyOption(code: 'USD', symbol: '\$', name: 'US dollar');
  const yen = CurrencyOption(
    code: 'JPY',
    symbol: '\u00A5',
    name: 'Japanese yen',
    decimals: 0,
  );

  group('Validators.parseAmount', () {
    test('converts decimal input to minor units', () {
      expect(Validators.parseAmount('12', 2), 1200);
      expect(Validators.parseAmount('12.5', 2), 1250);
      expect(Validators.parseAmount('12,05', 2), 1205);
    });

    test('rejects malformed input', () {
      expect(Validators.parseAmount('abc', 2), isNull);
      expect(Validators.parseAmount('1.234', 2), isNull);
      expect(Validators.parseAmount('1.5', 0), isNull);
      expect(Validators.parseAmount('', 2), isNull);
    });
  });

  group('Validators.amount', () {
    test('explains what is wrong', () {
      expect(Validators.amount('', usd), 'Enter an amount');
      expect(Validators.amount('0', usd), 'Amount must be greater than zero');
      expect(Validators.amount('x', usd), isNotNull);
      expect(Validators.amount('9.99', usd), isNull);
      expect(Validators.amount('1200', yen), isNull);
    });
  });

  group('CurrencyOption', () {
    test('formats minor units', () {
      expect(usd.format(123456), '\$1,234.56');
      expect(yen.format(1200), '\u00A51,200');
      expect(usd.formatPlain(1250), '12.50');
    });

    test('renders the NPR symbol with a space before the number', () {
      final npr = CurrencyOption.supported.firstWhere((c) => c.code == 'NPR');
      expect(npr.format(125000), 'रु 1,250.00');
    });
  });

  group('Expense', () {
    test('round-trips through its storage map', () {
      final expense = Expense(
        id: 3,
        amountMinor: 1250,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 9, 4),
        note: 'Bus pass',
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.amountMinor, 1250);
      expect(restored.category, ExpenseCategory.transport);
      expect(restored.date, DateTime(2026, 9, 4));
      expect(restored.note, 'Bus pass');
    });
  });

  group('date utils', () {
    test('daysBetween ignores time of day', () {
      expect(daysBetween(DateTime(2026, 9, 1), DateTime(2026, 9, 3, 23)), 2);
    });

    test('toDateKey pads month and day', () {
      expect(toDateKey(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });
}
