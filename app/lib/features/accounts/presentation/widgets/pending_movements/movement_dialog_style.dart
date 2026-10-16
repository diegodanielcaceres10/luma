import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/app_clock.dart';
import '../../../../../core/widgets/input_text_field.dart';

/// Shared with the statement review sheet so its dialogs look like these.
const kMovementDialogLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextSecondary,
);

/// Same decoration as [InputTextField] in compact mode, for the dropdowns and
/// date pickers that sit next to its fields.
const kMovementDialogFieldDecoration = InputTextField.compactDecoration;

/// Date a dialog starts on: [preferred] clamped into [range] (any date from
/// 2020 up to today when null), or the range's end when there is none.
DateTime initialMovementDialogDate(DateTime? preferred, DateTimeRange? range) {
  final first = range?.start ?? DateTime(2020);
  final last = range?.end ?? nowLocal();
  if (preferred == null || preferred.isAfter(last)) return last;
  return preferred.isBefore(first) ? first : preferred;
}
