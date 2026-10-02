import 'package:flutter/material.dart';

/// First day of the current month up to today (date only). Used to bound the
/// dates a movement can take when justifying the current month.
DateTimeRange currentMonthRange([DateTime? now]) {
  final today = now ?? DateTime.now();
  return DateTimeRange(
    start: DateTime(today.year, today.month),
    end: DateTime(today.year, today.month, today.day),
  );
}
