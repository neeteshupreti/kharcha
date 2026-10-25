import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:expense_tracker/models/saving_category.dart';
import 'package:flutter/foundation.dart';

@immutable
class Saving {
  const Saving({
    this.id,
    required this.amountMinor,
    required this.category,
    required this.date,
    this.note = '',
  });

  factory Saving.fromMap(Map<String, Object?> map) {
    return Saving(
      id: map['id'] as int,
      amountMinor: map['amount_minor'] as int,
      category: SavingCategory.fromName(map['category'] as String?),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  /// Null until the saving has been stored.
  final int? id;

  /// Amount in the currency's minor unit (cents), so sums are exact.
  final int amountMinor;
  final SavingCategory category;

  /// Calendar day of the saving, at local midnight.
  final DateTime date;
  final String note;

  Saving copyWith({
    int? id,
    int? amountMinor,
    SavingCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Saving(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount_minor': amountMinor,
      'category': category.name,
      'date': toDateKey(date),
      'note': note.isEmpty ? null : note,
    };
  }
}
