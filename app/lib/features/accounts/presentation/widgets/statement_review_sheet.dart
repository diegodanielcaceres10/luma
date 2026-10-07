import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/scanned_movement.dart';
import 'pending_movements_section.dart';
import 'statement_review/edit_scanned_dialog.dart';
import 'statement_review/review_tile.dart';

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
  late final List<StatementReviewItem> _items;

  DateTimeRange get _range =>
      widget.dateRange ??
      DateTimeRange(start: DateTime(2020), end: nowLocal());

  @override
  void initState() {
    super.initState();
    _items = widget.movements.map(StatementReviewItem.new).toList();
    for (final item in _items) {
      _refreshFlags(item);
      item.selected = item.inRange && !item.duplicate;
    }
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A line without a date counts as in range: it is saved on the range's
  /// last day, like the manual dialogs do.
  void _refreshFlags(StatementReviewItem item) {
    final date = item.movement.date;
    final range = _range;
    item.inRange = date == null ||
        (!_dayOf(date).isBefore(_dayOf(range.start)) &&
            !_dayOf(date).isAfter(_dayOf(range.end)));
    item.duplicate = isPossibleDuplicate(item.movement, widget.known);
  }

  Iterable<StatementReviewItem> get _selected => _items.where((i) => i.selected);

  double get _selectedTotal {
    final cents = _selected.fold<int>(
      0,
      (sum, i) => sum + (i.movement.signedAmount * 100).round(),
    );
    return cents / 100;
  }

  Future<void> _edit(StatementReviewItem item) async {
    final edited = await showDialog<EditScannedResult>(
      context: context,
      builder: (dialogContext) => EditScannedDialog(
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
                  return StatementReviewTile(
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
