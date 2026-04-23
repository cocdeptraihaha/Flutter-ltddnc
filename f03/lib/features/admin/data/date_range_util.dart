import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatQueryDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

/// Mặc định: 7 ngày gần nhất.
DateTimeRange defaultLast7Days() {
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 6));
  return DateTimeRange(
    start: startOfDay(from),
    end: endOfDay(to),
  );
}
