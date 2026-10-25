import 'package:expense_tracker/core/utils/date_utils.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';

abstract final class Formatters {
  static final DateFormat _weekdayDay = DateFormat('EEEE, d MMM');
  static final DateFormat _weekdayDayYear = DateFormat('EEEE, d MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _fullDate = DateFormat('d MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _monthName = DateFormat('MMMM');
  static final DateFormat _monthShort = DateFormat('MMM');

  static String dayHeading(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final daysAgo = daysBetween(date, today);
    if (daysAgo == 0) {
      return 'Today';
    }
    if (daysAgo == 1) {
      return 'Yesterday';
    }
    return date.year == today.year
        ? _weekdayDay.format(date)
        : _weekdayDayYear.format(date);
  }

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String monthName(DateTime date) => _monthName.format(date);

  static String monthShort(DateTime date) => _monthShort.format(date);

  static String rangeLabel(DateTimeRange range) {
    if (range.start == range.end) {
      return _fullDate.format(range.start);
    }
    final sameYear = range.start.year == range.end.year;
    final start = sameYear
        ? _dayMonth.format(range.start)
        : _fullDate.format(range.start);
    return '$start \u2013 ${_fullDate.format(range.end)}';
  }

  static String percent(double fraction) => '${(fraction * 100).round()}%';
}
