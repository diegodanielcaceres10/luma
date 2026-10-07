import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

/// Text field shared by the forms and dialogs: an optional label above and
/// the field below, styled like the rest of the auth-themed screens.
///
/// [compact] switches to the denser look used inside dialogs. Controls that
/// sit next to a field and must look like it (dropdowns, date pickers) can
/// use [formDecoration] or [compactDecoration].
class InputTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool compact;
  final bool? enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const InputTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.compact = false,
    this.enabled,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  /// Decoration of fields in full-screen forms.
  static const formDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.authCardFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authAccent),
    ),
    hintStyle: TextStyle(color: AppColors.authTextFooter),
  );

  /// Denser decoration, for fields inside dialogs and sheets.
  static const compactDecoration = InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.authCardFill,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    hintStyle: TextStyle(color: AppColors.authTextFooter),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authAccent),
    ),
  );

  static const _formLabelStyle = TextStyle(color: AppColors.authTextSecondary);

  static const _compactLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextSecondary,
  );

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppColors.authTextPrimary),
      decoration: (compact ? compactDecoration : formDecoration).copyWith(
        hintText: hintText,
      ),
      validator: validator,
      onChanged: onChanged,
    );

    final label = this.label;
    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: compact ? _compactLabelStyle : _formLabelStyle),
        SizedBox(height: compact ? 6 : 8),
        field,
      ],
    );
  }
}
