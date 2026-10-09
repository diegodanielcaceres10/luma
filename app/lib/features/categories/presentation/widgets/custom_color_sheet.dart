import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `show` because the package also exports `colorFromHex` / `colorToHex`,
// which would clash with the ones in category_visuals.dart.
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    show ColorPicker, PaletteType;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/widgets/primary_button.dart';

/// Bottom sheet to pick a custom color. Returns '#RRGGBB' on confirm, or
/// `null` if dismissed.
class CustomColorSheet extends StatefulWidget {
  final Color initialColor;

  const CustomColorSheet({super.key, required this.initialColor});

  @override
  State<CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<CustomColorSheet> {
  // Keep the HSV (not just the Color): going through RGB loses the hue for
  // grays/black/white and the slider would jump while dragging.
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController =
        TextEditingController(text: _hexDigits(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  /// 'RRGGBB' without the '#', as shown in the text field.
  String _hexDigits(Color color) => colorToHex(color).substring(1);

  void _onPickerChanged(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hexController.text = _hexDigits(hsv.toColor());
    });
  }

  void _onHexChanged(String value) {
    // Only update once the code is complete, to not overwrite typing.
    if (value.length != 6) return;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed)));
  }

  InputDecoration _hexDecoration() {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.authCardFill,
      hintText: 'RRGGBB',
      hintStyle: const TextStyle(color: AppColors.authTextFooter),
      prefixText: '#',
      prefixStyle: const TextStyle(color: AppColors.authTextSecondary),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.authCardBorder),
      enabledBorder: border(AppColors.authCardBorder),
      focusedBorder: border(AppColors.authAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    // Near-black tones are hard to see on the app's dark background.
    final isTooDark = color.computeLuminance() < 0.05;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.authCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color personalizado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ColorPicker(
                  pickerColor: color,
                  pickerHsvColor: _hsv,
                  onColorChanged: (_) {},
                  onHsvColorChanged: _onPickerChanged,
                  paletteType: PaletteType.hsvWithHue,
                  // Stored as '#RRGGBB': no alpha channel.
                  enableAlpha: false,
                  labelTypes: const [],
                  displayThumbColor: true,
                  portraitOnly: true,
                  colorPickerWidth:
                      constraints.maxWidth.clamp(240.0, 340.0).toDouble(),
                  pickerAreaHeightPercent: 0.7,
                  pickerAreaBorderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    maxLength: 6,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    cursorColor: AppColors.authAccent,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        ),
                      ),
                    ],
                    decoration: _hexDecoration(),
                    onChanged: _onHexChanged,
                  ),
                ),
              ],
            ),
            if (isTooDark) ...[
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.authExpense,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este color es muy oscuro y puede costar verlo sobre '
                      'el fondo de la app.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.authTextSecondary,
                      side: const BorderSide(color: AppColors.authCardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Usar color',
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.pop(context, colorToHex(color)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
