import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/image_crop_picker.dart';
import '../../../../core/widgets/ai_image_source_sheet.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../data/models/account.dart';
import '../../data/models/scanned_movement.dart';
import '../../data/services/statement_scan_service.dart';
import '../view_models/account_view_model.dart';
import 'pending_movements/add_invoice_dialog.dart';
import 'pending_movements/add_movement_dialog.dart';
import 'pending_movements/add_transfer_dialog.dart';
import 'pending_movements/movement_type_sheet.dart';
import 'pending_movements/movements_list.dart';
import 'pending_movements/pending_movement.dart';
import 'pending_movements/pending_movements_controller.dart';
import 'pending_movements/select_pending_invoice_sheet.dart';
import 'statement_review_sheet.dart';

export 'pending_movements/movement_dialog_style.dart'
    show kMovementDialogFieldDecoration, kMovementDialogLabelStyle;
export 'pending_movements/pending_movement.dart' hide kMonthAbbreviations;
export 'pending_movements/pending_movements_controller.dart';
export 'pending_movements/pending_movements_read_only_list.dart';

/// Header, "Add movement" button and accumulated list for a set of
/// [PendingMovement]s backed by [controller]. Tapping the button walks the
/// user through picking a type (income, expense, transfer or service
/// invoice) and filling in its details; the result is pushed into
/// [controller], which redraws this widget.
///
/// [helperText], when provided, is shown between the header and the list
/// (e.g. how much of a difference is still unjustified).
class PendingMovementsSection extends StatelessWidget {
  final PendingMovementsController controller;

  final Account currentAccount;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;

  final String currency;
  final String title;
  final Widget? helperText;
  final bool enabled;

  /// Dates the add-movement dialogs accept, and the one they start on (its
  /// end). Defaults to any date from 2020 up to today.
  final DateTimeRange? dateRange;

  /// Transactions already saved, used to flag scanned statement lines that
  /// may duplicate one of this account's movements. Optional: without it
  /// only lines already queued in [controller] are checked.
  final List<TransactionEntry> existingTransactions;

  /// Reads statement screenshots. Defaults to the Supabase-backed service;
  /// override it in tests.
  final StatementScanService? scanService;

  const PendingMovementsSection({
    super.key,
    required this.controller,
    required this.currentAccount,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.currency,
    this.title = 'Movimientos para justificar la diferencia',
    this.helperText,
    this.enabled = true,
    this.dateRange,
    this.existingTransactions = const [],
    this.scanService,
  });

  /// Opens the bottom sheet behind the "Add movement" button (or, with
  /// [editing], behind a row's pencil icon, replacing that row with the
  /// result and carrying over its amount, date and description) to pick between
  /// Expense, Income, Service invoice and Transfer ([PendingMovementKind]),
  /// Expense and Income open
  /// [AddMovementDialog] with categories filtered by that
  /// type. Transfer opens [AddTransferDialog] to choose the other account
  /// and the direction. Service invoice first opens
  /// [SelectPendingInvoiceSheet] to pick one and, if its category resolves,
  /// [AddInvoiceDialog] to confirm amount and date.
  Future<void> _showMovementFlow(
    BuildContext context, {
    PendingMovement? editing,
  }) async {
    final PendingMovementKind? type;
    if (editing == null) {
      type = await _pickKind(context);
    } else {
      // The sign already says whether it is an income or an expense, so the
      // sheet offers "Categorizar" instead of asking for that again. A
      // service invoice is always an expense.
      final isExpense = editing.amount < 0;
      type = await _pickKind(
        context,
        title: 'Editar movimiento',
        categorizeKind: isExpense
            ? PendingMovementKind.expense
            : PendingMovementKind.income,
        offerInvoice: isExpense,
      );
    }
    if (type == null || !context.mounted) return;

    void save(PendingMovement movement) => editing == null
        ? controller.add(movement)
        : controller.replace(editing, movement);

    switch (type) {
      case PendingMovementKind.income:
      case PendingMovementKind.expense:
        final categoryType =
            type == PendingMovementKind.income ? 'income' : 'expense';
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => AddMovementDialog(
            categoryViewModel: categoryViewModel,
            categoryType: categoryType,
            onSave: save,
            dateRange: dateRange,
            initial: editing,
          ),
        );
      case PendingMovementKind.transfer:
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => AddTransferDialog(
            currentAccount: currentAccount,
            accountViewModel: accountViewModel,
            onSave: save,
            dateRange: dateRange,
            initial: editing,
          ),
        );
      case PendingMovementKind.invoice:
        return _showAddInvoiceFlow(context, save: save, editing: editing);
    }
  }

  Future<PendingMovementKind?> _pickKind(
    BuildContext context, {
    String title = 'Agregar movimiento',
    PendingMovementKind? categorizeKind,
    bool offerInvoice = true,
  }) {
    return showModalBottomSheet<PendingMovementKind>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MovementTypeSheet(
        title: title,
        categorizeKind: categorizeKind,
        offerInvoice: offerInvoice,
      ),
    );
  }

  /// Second half of the "Service invoice" case of [_showMovementFlow]:
  /// pick which invoice to pay (excluding those already queued in
  /// [controller], so one can't be paid twice before saving) and, if the
  /// service has a resolved category, confirm amount and date.
  Future<void> _showAddInvoiceFlow(
    BuildContext context, {
    required void Function(PendingMovement movement) save,
    PendingMovement? editing,
  }) async {
    // The invoice of the movement being edited stays selectable.
    final alreadyQueuedIds = controller.movements
        .where((m) => m != editing)
        .whereType<InvoicePendingMovement>()
        .map((m) => m.invoice.id)
        .toSet();
    final pendingInvoices = invoiceViewModel.invoices
        .where((i) => i.isPending && !alreadyQueuedIds.contains(i.id))
        .toList();

    final invoice = await showModalBottomSheet<Invoice>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SelectPendingInvoiceSheet(
        invoices: pendingInvoices,
        serviceViewModel: serviceViewModel,
        currency: accountViewModel.primaryCurrency,
      ),
    );
    if (invoice == null || !context.mounted) return;

    final service = serviceViewModel.serviceById(invoice.serviceId);
    final serviceName = service?.name ?? 'Servicio eliminado';
    final category = categoryViewModel.categoryById(service?.categoryId);
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servicio no tiene categoría o fue eliminado; no se puede '
            'registrar el pago.',
          ),
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AddInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        onSave: save,
        dateRange: dateRange,
        initial: editing,
      ),
    );
  }

  /// "Importar desde una captura" flow: pick an image, have it read, let the
  /// user review the detected lines and queue the confirmed ones in
  /// [controller]. Only income and expense lines are detected; transfers and
  /// invoices are still added by hand.
  Future<void> _importFromImage(BuildContext context) async {
    // Statements are read from existing files, never from a fresh photo.
    final source = await showAiImageSourceSheet(
      context,
      title: 'Importar desde una captura',
      allowCamera: false,
    );
    if (source == null || !context.mounted) return;

    final image = await pickAndCropImage(context, source, maxWidth: 2000);
    if (image == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.authAccent),
        ),
      ),
    );

    final List<ScannedMovement> scanned;
    try {
      scanned =
          await (scanService ?? StatementScanService(Supabase.instance.client))
              .scan(imageBytes: image.bytes, mimeType: image.mimeType);
    } catch (_) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Servicio no disponible. Intente más tarde o consulte a su '
            'administrador.',
          ),
        ),
      );
      return;
    }
    navigator.pop();

    if (!context.mounted) return;
    if (scanned.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se detectaron movimientos en la imagen.'),
        ),
      );
      return;
    }

    final known = <KnownMovement>[];
    for (final m in controller.movements) {
      known.add((amount: m.amount, date: m.date));
    }
    for (final t in existingTransactions) {
      if (t.account.id != currentAccount.id) continue;
      known.add((
        amount: t.type == 'expense' ? -t.amount : t.amount,
        date: t.date,
      ));
    }

    final confirmed = await showStatementReviewSheet(
      context,
      movements: scanned,
      currency: currency,
      categoryViewModel: categoryViewModel,
      dateRange: dateRange,
      known: known,
    );
    if (confirmed == null) return;
    confirmed.forEach(controller.add);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final movements = controller.movements;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MovementsSectionHeader(
              title: title,
              onAddMovement: () => _showMovementFlow(context),
              enabled: enabled,
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              helperText!,
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: enabled ? () => _importFromImage(context) : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.authAccent,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: const Text(
                  'Importar desde una captura',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (movements.isNotEmpty) ...[
              const SizedBox(height: 12),
              MovementsList(
                movements: movements,
                currency: currency,
                onDelete: controller.remove,
                onEdit: (movement) =>
                    _showMovementFlow(context, editing: movement),
                enabled: enabled,
              ),
            ],
          ],
        );
      },
    );
  }
}
