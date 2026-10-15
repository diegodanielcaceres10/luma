import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/text_action_button.dart';
import '../../data/models/scanned_movement.dart';
import 'pending_movements_section.dart';
import 'statement_review/edit_scanned_dialog.dart';
import 'statement_review/review_tile.dart';

/// Lets the user review [movements] read from a statement and returns the
/// ones they confirm as [PendingMovement]s (null if they dismiss the sheet).
///
/// Only the description of a line can be corrected. Lines outside [dateRange]
/// start unselected and can't be added; lines that match something in
/// [known] are flagged as possible duplicates and also start unselected.
/// Lines whose description mentions a transfer are added as transfers unless
/// the user unticks them.
Future<List<PendingMovement>?> showStatementReviewSheet(
  BuildContext context, {
  required List<ScannedMovement> movements,
  required String currency,
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
      dateRange: dateRange,
      known: known.toList(),
    ),
  );
}

class _StatementReviewSheet extends StatefulWidget {
  final List<ScannedMovement> movements;
  final String currency;
  final DateTimeRange? dateRange;
  final List<KnownMovement> known;

  const _StatementReviewSheet({
    required this.movements,
    required this.currency,
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
      _refreshTransfer(item);
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

  /// Flags the line as a transfer when its description says so; the box
  /// starts ticked only the first time the flag turns on.
  void _refreshTransfer(StatementReviewItem item) {
    final wasTransfer = item.isTransfer;
    item.isTransfer = mentionsTransfer(item.movement.description);
    if (item.isTransfer && !wasTransfer) item.asTransfer = true;
    if (!item.isTransfer) item.asTransfer = false;
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
    final description = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          EditScannedDialog(description: item.movement.description),
    );
    if (description == null || !mounted) return;

    setState(() {
      item.movement = ScannedMovement(
        type: item.movement.type,
        amount: item.movement.amount,
        date: item.movement.date,
        description: description.isEmpty ? null : description,
      );
      _refreshTransfer(item);
    });
  }

  void _confirm() {
    final range = _range;
    final result = _selected.map<PendingMovement>((i) {
      final date = i.movement.date ?? range.end;
      if (i.asTransfer) {
        return TransferPendingMovement(
          amount: i.movement.signedAmount,
          description: i.movement.description,
          date: date,
        );
      }
      return CategoryPendingMovement(
        amount: i.movement.signedAmount,
        type: i.movement.type,
        description: i.movement.description,
        date: date,
      );
    }).toList();
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
                    onToggleTransfer: (value) =>
                        setState(() => item.asTransfer = value ?? false),
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
                TextActionButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                PrimaryButton(
                  label: 'Agregar',
                  onPressed: selectedCount == 0 ? null : _confirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
