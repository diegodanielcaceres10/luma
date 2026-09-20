import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `show` porque el paquete también exporta `colorFromHex` / `colorToHex`, que
// chocarían con los de category_visuals.dart (los que usa el resto de la app).
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    show ColorPicker, PaletteType;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';

/// Contenido de la pestaña "Nueva categoría" / "Editar categoría". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
///
/// Si [category] viene nulo, es un alta nueva (con [initialType] fijo).
/// Si viene con valor, es edición — el tipo se puede seguir cambiando.
class CategoryFormTab extends StatefulWidget {
  final String userId;
  final CategoryViewModel categoryViewModel;
  final Category? category;
  final String initialType;

  /// Se llama tras guardar o eliminar con éxito, o al cancelar, para volver
  /// a "Categorías".
  final VoidCallback onDone;

  const CategoryFormTab({
    super.key,
    required this.userId,
    required this.categoryViewModel,
    required this.onDone,
    this.category,
    this.initialType = 'expense',
  });

  @override
  State<CategoryFormTab> createState() => _CategoryFormTabState();
}

class _CategoryFormTabState extends State<CategoryFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late String _type;
  late String _selectedColor;
  late bool _hasBudget;

  bool get _isEditing => widget.category != null;

  static const _fieldDecoration = InputDecoration(
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
  );

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController.text = category?.name ?? '';
    _type = category?.type ?? widget.initialType;
    _selectedColor = category?.color ?? kCategoryColors.first;
    _hasBudget = category?.hasBudget ?? false;
    _budgetController.text =
        category != null ? (category.budgetAmount ?? 0).toStringAsFixed(2) : '';
    widget.categoryViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.categoryViewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.categoryViewModel;
    // El presupuesto solo aplica a gastos — si el tipo es 'income', se
    // ignora aunque el switch haya quedado prendido de un cambio previo.
    final effectiveHasBudget = _type == 'expense' && _hasBudget;
    final effectiveBudgetAmount =
        effectiveHasBudget ? double.parse(_budgetController.text.trim()) : null;

    final success = _isEditing
        ? await vm.updateCategory(
            id: widget.category!.id,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
          )
        : await vm.createCategory(
            userId: widget.userId,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
          );

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'No se pudo guardar.')),
      );
    }
  }

  /// Abre el selector de color libre. Si el usuario confirma, el color
  /// elegido queda como `_selectedColor` (en formato '#RRGGBB', el mismo que
  /// ya se guarda en `categories.color`).
  Future<void> _openCustomColorPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomColorSheet(
        initialColor: colorFromHex(_selectedColor),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedColor = picked);
    }
  }

  Widget _buildColorDot({required String hex, required VoidCallback? onTap}) {
    final color = colorFromHex(hex);
    final isSelected = hex == _selectedColor;
    // Con colores libres puede haber tonos muy claros: el check blanco fijo
    // no se vería, así que se elige según el brillo del color.
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.authTextPrimary, width: 2)
              : null,
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, color: checkColor, size: 20)
            : null,
      ),
    );
  }

  /// Botón "+" al final de la fila de colores: abre el selector libre.
  Widget _buildAddColorButton({required VoidCallback? onTap}) {
    return Tooltip(
      message: 'Color personalizado',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.authAccent.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.authAccent,
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.categoryViewModel.isSubmitting;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (isSubmitting)
              const LinearProgressIndicator(
                backgroundColor: AppColors.authCardBorder,
                color: AppColors.authAccent,
                minHeight: 3,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: isSubmitting ? null : widget.onDone,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back_rounded,
                              color: AppColors.authTextPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Editar categoría' : 'Nueva categoría',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Nombre',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration.copyWith(
                      hintText: 'Ej: Suscripciones',
                      hintStyle:
                          const TextStyle(color: AppColors.authTextFooter),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Tipo',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AppColors.authCardFill,
                      foregroundColor: AppColors.authTextSecondary,
                      selectedBackgroundColor: AppColors.authAccent,
                      selectedForegroundColor: AppColors.authBackgroundBottom,
                      side: const BorderSide(color: AppColors.authCardBorder),
                    ),
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Gasto')),
                      ButtonSegment(value: 'income', label: Text('Ingreso')),
                    ],
                    selected: {_type},
                    onSelectionChanged: isSubmitting
                        ? null
                        : (selection) =>
                            setState(() => _type = selection.first),
                  ),
                  const SizedBox(height: 20),
                  const Text('Color',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final hex in kCategoryColors)
                        _buildColorDot(
                          hex: hex,
                          onTap: isSubmitting
                              ? null
                              : () => setState(() => _selectedColor = hex),
                        ),
                      // Color libre ya elegido (no está en la paleta rápida):
                      // se muestra seleccionado y, al tocarlo, reabre el
                      // selector para ajustarlo.
                      if (!kCategoryColors.contains(_selectedColor))
                        _buildColorDot(
                          hex: _selectedColor,
                          onTap: isSubmitting ? null : _openCustomColorPicker,
                        ),
                      _buildAddColorButton(
                        onTap: isSubmitting ? null : _openCustomColorPicker,
                      ),
                    ],
                  ),
                  if (_type == 'expense') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Presupuesto mensual',
                              style: TextStyle(
                                  color: AppColors.authTextSecondary)),
                        ),
                        Switch(
                          value: _hasBudget,
                          activeThumbColor: AppColors.authAccent,
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() => _hasBudget = value),
                        ),
                      ],
                    ),
                    if (_hasBudget) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _budgetController,
                        enabled: !isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                        decoration: _fieldDecoration.copyWith(
                          hintText: '0.00',
                          hintStyle:
                              const TextStyle(color: AppColors.authTextFooter),
                        ),
                        validator: (value) {
                          if (!_hasBudget) return null;
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Ingresa un monto válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.authAccent,
                        foregroundColor: AppColors.authBackgroundBottom,
                        disabledBackgroundColor:
                            AppColors.authAccent.withValues(alpha: 0.6),
                        disabledForegroundColor: AppColors.authBackgroundBottom
                            .withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.authBackgroundBottom,
                              ),
                            )
                          : Text(_isEditing
                              ? 'Guardar cambios'
                              : 'Crear categoría'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet para elegir un color libre: área de saturación/brillo con
/// slider de tono (paquete `flutter_colorpicker`) más un campo hexadecimal.
/// Devuelve el color elegido como '#RRGGBB' al confirmar, o `null` si se
/// cancela / se cierra el sheet.
class _CustomColorSheet extends StatefulWidget {
  final Color initialColor;

  const _CustomColorSheet({required this.initialColor});

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  // Se guarda el HSV (y no solo el Color) porque al pasar por RGB se pierde
  // el tono en grises/negro/blanco y el slider "saltaría" al arrastrar.
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

  /// 'RRGGBB' (sin el '#'), que es lo que muestra el campo de texto.
  String _hexDigits(Color color) => colorToHex(color).substring(1);

  void _onPickerChanged(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hexController.text = _hexDigits(hsv.toColor());
    });
  }

  void _onHexChanged(String value) {
    // Se actualiza recién cuando el código está completo, para no pisar lo
    // que el usuario está escribiendo.
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
    // Sobre el fondo oscuro de la app, un tono casi negro no se distingue.
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
                  // Se guarda '#RRGGBB': sin canal alfa.
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
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.authAccent,
                      foregroundColor: AppColors.authBackgroundBottom,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, colorToHex(color)),
                    child: const Text('Usar color'),
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
