DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime monthStart(DateTime value) => DateTime(value.year, value.month);

DateTime addMonths(DateTime month, int delta) {
  return DateTime(month.year, month.month + delta);
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// Last calendar day of [month], at local midnight (00:00:00).
DateTime endOfMonth(DateTime month) => DateTime(month.year, month.month + 1, 0);

/// Whole calendar days from [from] to [to], unaffected by daylight saving.
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

/// Sortable, locale-independent key used for storage: `yyyy-MM-dd`.
String toDateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-$month-$day';
}
