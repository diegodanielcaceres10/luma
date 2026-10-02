import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/scanned_movement.dart';
import 'pending_movements_section.dart';

/// Asks where the statement screenshot comes from. Resolves to null when the
/// user dismisses the sheet.
Future<ImageSource?> showStatementSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.authBackgroundBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importar desde una captura',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _PrivacyNotice(),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.authTextPrimary,
              ),
              title: const Text(
                'Elegir de la galería',
                style: TextStyle(color: AppColors.authTextPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.photo_camera_rounded,
                color: AppColors.authTextPrimary,
              ),
              title: const Text(
                'Sacar foto',
                style: TextStyle(color: AppColors.authTextPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Warning shown every time before a statement image is picked. The image is
/// read by a free-tier AI service whose provider may use and review it.
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.authExpense.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.authExpense.withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.authExpense,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta función es de uso personal y con fines educativos y de '
              'desarrollo. La captura se envía a un servicio de IA gratuito '
              '(Gemini): Google puede usarla para mejorar sus productos y '
              'personas de su equipo podrían leerla.\n\n'
              'Recortala para que solo se vean las líneas de movimientos. '
              'No incluyas datos sensibles (tu nombre, números de cuenta o '
              'de tarjeta, documentos) ni nada que no quieras compartir.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the user review [movements] read from a statement and returns the
/// ones they confirm as [PendingMovement]s (null if they dismiss the sheet).
///
/// Lines outside [dateRange] start unselected and can be fixed by editing
/// their date; lines that match something in [known] are flagged as possible
/// duplicates and also start unselected.
Future<List<PendingMovement>?> showStatementReviewSheet(
  BuildContext context, {
  required List<ScannedMovement> movements,
  required String currency,
  required CategoryViewModel categoryViewModel,
  required DateTimeRange? dateRange,
  required Iterable<KnownMovement> known,
}) {
  return showModalBottomSheet<List<PendingMovement>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.authBackgroundBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _StatementReviewSheet(
      movements: movements,
      currency: currency,
      categoryViewModel: categoryViewModel,
      dateRange: dateRange,
      known: known.toList(),
    ),
  );
}

class _ReviewItem {
  ScannedMovement movement;
  Category? category;
  bool selected = false;
  bool inRange = true;
  bool duplicate = false;

  _ReviewItem(this.movement);
}

class _StatementReviewSheet extends StatefulWidget {
  final List<ScannedMovement> movements;
  final String currency;
  final CategoryViewModel categoryViewModel;
  final DateTimeRange? dateRange;
  final List<KnownMovement> known;

  const _StatementReviewSheet({
    required this.movements,
    required this.currency,
    required this.categoryViewModel,
    required this.dateRange,
    required this.known,
  });

  @override
  State<_StatementReviewSheet> createState() => _StatementReviewSheetState();
}

class _StatementReviewSheetState extends State<_StatementReviewSheet> {
  late final List<_ReviewItem> _items;

  DateTimeRange get _range =>
      widget.dateRange ??
      DateTimeRange(start: DateTime(2020), end: nowLocal());

  @override
  void initState() {
    super.initState();
    _items = widget.movements.map(_ReviewItem.new).toList();
    for (final item in _items) {
      _refreshFlags(item);
      item.selected = item.inRange && !item.duplicate;
    }
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A line without a date counts as in range: it is saved on the range's
  /// last day, like the manual dialogs do.
  void _refreshFlags(_ReviewItem item) {
    final date = item.movement.date;
    final range = _range;
    item.inRange = date == null ||
        (!_dayOf(date).isBefore(_dayOf(range.start)) &&
            !_dayOf(date).isAfter(_dayOf(range.end)));
    item.duplicate = isPossibleDuplicate(item.movement, widget.known);
  }

  Iterable<_ReviewItem> get _selected => _items.where((i) => i.selected);

  double get _selectedTotal {
    final cents = _selected.fold<int>(
      0,
      (sum, i) => sum + (i.movement.signedAmount * 100).round(),
    );
    return cents / 100;
  }

  Future<void> _edit(_ReviewItem item) async {
    final edited = await showDialog<_EditResult>(
      context: context,
      builder: (dialogContext) => _EditScannedDialog(
        movement: item.movement,
        category: item.category,
        categoryViewModel: widget.categoryViewModel,
        range: _range,
      ),
    );
    if (edited == null || !mounted) return;

    setState(() {
      item.movement = edited.movement;
      item.category = edited.category;
      _refreshFlags(item);
      if (!item.inRange) item.selected = false;
    });
  }

  void _confirm() {
    final range = _range;
    final result = _selected
        .map(
          (i) => CategoryPendingMovement(
            amount: i.movement.signedAmount,
            type: i.movement.type,
            category: i.category,
            description: i.movement.description,
            date: i.movement.date ?? range.end,
          ),
        )
        .toList();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;
    final total = _selectedTotal;
    final totalText = total > 0
        ? '+${formatCurrency(total, widget.currency)}'
        : formatCurrency(total, widget.currency);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.authCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Movimientos detectados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Revisalos antes de agregarlos. Tocá una línea para corregirla.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.authCardBorder,
                  height: 1,
                ),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return _ReviewTile(
                    item: item,
                    currency: widget.currency,
                    onToggle: (value) =>
                        setState(() => item.selected = value ?? false),
                    onEdit: () => _edit(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$selectedCount seleccionados · $totalText',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.authAccent,
                    foregroundColor: AppColors.authBackgroundBottom,
                  ),
                  onPressed: selectedCount == 0 ? null : _confirm,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final _ReviewItem item;
  final String currency;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;

  const _ReviewTile({
    required this.item,
    required this.currency,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final movement = item.movement;
    final amount = movement.signedAmount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    final date = movement.date;
    final dateText = date == null ? 'Sin fecha' : formatDate(date);

    String? warning;
    if (!item.inRange) {
      warning = 'Fuera del período';
    } else if (item.duplicate) {
      warning = 'Posible duplicado';
    }

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: item.selected,
              activeColor: AppColors.authAccent,
              checkColor: AppColors.authBackgroundBottom,
              side: const BorderSide(color: AppColors.authTextSecondary),
              onChanged: item.inRange ? onToggle : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.description ?? 'Sin descripción',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category?.name == null
                        ? dateText
                        : '$dateText · ${item.category!.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                  if (warning != null)
                    Text(
                      warning,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authExpense,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _EditResult {
  final ScannedMovement movement;
  final Category? category;

  const _EditResult(this.movement, this.category);
}

class _EditScannedDialog extends StatefulWidget {
  final ScannedMovement movement;
  final Category? category;
  final CategoryViewModel categoryViewModel;
  final DateTimeRange range;

  const _EditScannedDialog({
    required this.movement,
    required this.category,
    required this.categoryViewModel,
    required this.range,
  });

  @override
  State<_EditScannedDialog> createState() => _EditScannedDialogState();
}

class _EditScannedDialogState extends State<_EditScannedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _type = widget.movement.type;
  late DateTime _date = widget.movement.date ?? widget.range.end;
  late Category? _category = widget.category;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.movement.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.movement.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Keep the current date selectable even if it falls outside the range,
    // so the picker never receives an initialDate outside [first, last].
    final first = widget.range.start;
    final last = widget.range.end;
    final initial = _date.isBefore(first)
        ? first
        : (_date.isAfter(last) ? last : _date);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      _EditResult(
        ScannedMovement(
          type: _type,
          amount: amount,
          date: _date,
          description: description.isEmpty ? null : description,
        ),
        _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories
        .where((c) => c.type == _type)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Corregir movimiento',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                onSelectionChanged: (selection) => setState(() {
                  _type = selection.first;
                  // A category only fits the type it was created for.
                  if (_category?.type != _type) _category = null;
                }),
              ),
              const SizedBox(height: 16),
              const Text('Monto', style: kMovementDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration:
                    kMovementDialogFieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Descripción', style: kMovementDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: kMovementDialogFieldDecoration,
              ),
              const SizedBox(height: 16),
              const Text('Fecha', style: kMovementDialogLabelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: kMovementDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDate(_date),
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Categoría (opcional)',
                  style: kMovementDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<Category?>(
                  // initialValue is only read once; the key forces a rebuild
                  // when the type (and so the item list) changes.
                  key: ValueKey(_type),
                  initialValue: _category,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: kMovementDialogFieldDecoration,
                  items: [
                    const DropdownMenuItem<Category?>(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<Category?>(
                        value: c,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
