import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// A movement (income, expense, transfer or paid invoice) accumulated by
/// [PendingMovementsSection] before it is actually persisted. The owning
/// screen decides how (and whether) each one is turned into a real
/// transaction once the user confirms.
sealed class PendingMovement {
  final double amount;
  final String? description;
  final DateTime date;

  const PendingMovement({
    required this.amount,
    required this.date,
    this.description,
  });

  String get displayLabel;
}

class CategoryPendingMovement extends PendingMovement {
  /// Null when the movement was registered without a category.
  final Category? category;

  /// 'income' or 'expense'. Kept apart from [category] because it must
  /// survive a missing category.
  final String type;

  const CategoryPendingMovement({
    required super.amount,
    required super.date,
    required this.type,
    this.category,
    super.description,
  });

  @override
  String get displayLabel => category?.name ?? 'Sin categoría';
}

class TransferPendingMovement extends PendingMovement {
  final String otherAccountId;
  final String otherAccountName;

  const TransferPendingMovement({
    required super.amount,
    required super.date,
    required this.otherAccountId,
    required this.otherAccountName,
    super.description,
  });

  @override
  String get displayLabel => amount >= 0
      ? 'Transferencia desde $otherAccountName'
      : 'Transferencia a $otherAccountName';
}

class InvoicePendingMovement extends PendingMovement {
  final Invoice invoice;
  final Category category;
  final String serviceName;

  const InvoicePendingMovement({
    required super.amount,
    required super.date,
    required this.invoice,
    required this.category,
    required this.serviceName,
    super.description,
  });

  @override
  String get displayLabel => 'Factura · $serviceName';
}

/// Holds the [PendingMovement]s accumulated by a [PendingMovementsSection]
/// so the owning screen can read them (and their [total]) when it is time to
/// persist or discard them. The screen owns the controller's lifecycle and
/// must call [dispose] once it is done with it.
class PendingMovementsController extends ChangeNotifier {
  final List<PendingMovement> _movements = [];

  List<PendingMovement> get movements => List.unmodifiable(_movements);

  bool get isEmpty => _movements.isEmpty;
  bool get isNotEmpty => _movements.isNotEmpty;

  /// Sum of every accumulated movement's signed amount, rounded to cents so
  /// repeated double addition doesn't leave remainders.
  double get total {
    final cents = _movements.fold<int>(
      0,
      (sum, movement) => sum + (movement.amount * 100).round(),
    );
    return cents / 100;
  }

  void add(PendingMovement movement) {
    _movements.add(movement);
    notifyListeners();
  }

  void remove(PendingMovement movement) {
    _movements.remove(movement);
    notifyListeners();
  }

  void removeWhere(bool Function(PendingMovement movement) test) {
    _movements.removeWhere(test);
    notifyListeners();
  }

  void clear() {
    _movements.clear();
    notifyListeners();
  }
}

const _kMonthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatMovementDate(DateTime date) {
  final month = _kMonthAbbreviations[date.month - 1];
  return '${date.day} $month ${date.year}';
}

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

  /// Which options the "Agregar movimiento" sheet offers. Defaults to all
  /// four; a screen that only makes sense for some of them (e.g. one that
  /// can't yet justify transfers or invoice payments without moving the
  /// balance) can pass a smaller set.
  final Set<PendingMovementKind> allowedKinds;

  /// Dates the add-movement dialogs accept, and the one they start on (its
  /// end). Defaults to any date from 2020 up to today.
  final DateTimeRange? dateRange;

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
    this.allowedKinds = const {
      PendingMovementKind.income,
      PendingMovementKind.expense,
      PendingMovementKind.transfer,
      PendingMovementKind.invoice,
    },
    this.dateRange,
  });

  /// Opens the bottom sheet behind the "Add movement" button to pick between
  /// Expense, Income, Service invoice and Transfer ([PendingMovementKind]),
  /// filtered down to [allowedKinds]. Expense and Income open
  /// [_AddMovementDialog] with categories filtered by that
  /// type. Transfer opens [_AddTransferDialog] to choose the other account
  /// and the direction. Service invoice first opens
  /// [_SelectPendingInvoiceSheet] to pick one and, if its category resolves,
  /// [_AddInvoiceDialog] to confirm amount and date.
  Future<void> _showAddMovementDialog(BuildContext context) async {
    final type = await showModalBottomSheet<PendingMovementKind>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MovementTypeSheet(allowedKinds: allowedKinds),
    );
    if (type == null || !context.mounted) return;

    switch (type) {
      case PendingMovementKind.income:
      case PendingMovementKind.expense:
        final categoryType =
            type == PendingMovementKind.income ? 'income' : 'expense';
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => _AddMovementDialog(
            categoryViewModel: categoryViewModel,
            categoryType: categoryType,
            onSave: controller.add,
            dateRange: dateRange,
          ),
        );
      case PendingMovementKind.transfer:
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => _AddTransferDialog(
            currentAccount: currentAccount,
            accountViewModel: accountViewModel,
            onSave: controller.add,
            dateRange: dateRange,
          ),
        );
      case PendingMovementKind.invoice:
        return _showAddInvoiceFlow(context);
    }
  }

  /// Second half of the "Service invoice" case of [_showAddMovementDialog]:
  /// pick which invoice to pay (excluding those already queued in
  /// [controller], so one can't be paid twice before saving) and, if the
  /// service has a resolved category, confirm amount and date.
  Future<void> _showAddInvoiceFlow(BuildContext context) async {
    final alreadyQueuedIds = controller.movements
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
      builder: (context) => _SelectPendingInvoiceSheet(
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
      builder: (dialogContext) => _AddInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        onSave: controller.add,
        dateRange: dateRange,
      ),
    );
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
            _MovementsSectionHeader(
              title: title,
              onAddMovement: () => _showAddMovementDialog(context),
              enabled: enabled,
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              helperText!,
            ],
            if (movements.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MovementsList(
                movements: movements,
                currency: currency,
                onDelete: controller.remove,
                enabled: enabled,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Read-only recap of already-queued movements, without the delete button
/// [_MovementsList] has — used in a review/confirmation step, after the
/// user is done adding them via [PendingMovementsSection].
class PendingMovementsReadOnlyList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;

  const PendingMovementsReadOnlyList({
    super.key,
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementReadOnlyTile(movement: movements[i], currency: currency),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovementReadOnlyTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  const _MovementReadOnlyTile({
    required this.movement,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              movement.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum PendingMovementKind { income, expense, transfer, invoice }

class _MovementTypeSheet extends StatelessWidget {
  final Set<PendingMovementKind> allowedKinds;

  const _MovementTypeSheet({required this.allowedKinds});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              'Agregar movimiento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (allowedKinds.contains(PendingMovementKind.expense))
              _MovementTypeOption(
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.authExpense,
                label: 'Gasto',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.expense),
              ),
            if (allowedKinds.contains(PendingMovementKind.income))
              _MovementTypeOption(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.authIncome,
                label: 'Ingreso',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.income),
              ),
            if (allowedKinds.contains(PendingMovementKind.invoice))
              _MovementTypeOption(
                icon: Icons.request_page_outlined,
                iconColor: AppColors.authInvoice,
                label: 'Factura de servicio',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.invoice),
              ),
            if (allowedKinds.contains(PendingMovementKind.transfer))
              _MovementTypeOption(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.authTransfer,
                label: 'Transferencia',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.transfer),
              ),
          ],
        ),
      ),
    );
  }
}

class _MovementTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MovementTypeOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementsSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAddMovement;

  final bool enabled;

  const _MovementsSectionHeader({
    required this.title,
    required this.onAddMovement,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onAddMovement : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.authAccent,
            side: const BorderSide(color: AppColors.authAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Agregar movimiento',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MovementsList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;
  final void Function(PendingMovement movement) onDelete;

  final bool enabled;

  const _MovementsList({
    required this.movements,
    required this.currency,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementListTile(
              movement: movements[i],
              currency: currency,
              onDelete: enabled ? () => onDelete(movements[i]) : null,
            ),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovementListTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  final VoidCallback? onDelete;

  const _MovementListTile({
    required this.movement,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                if (movement.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  formatMovementDate(movement.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.authTextSecondary,
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
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.authTextSecondary,
            ),
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

const _kDialogLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextSecondary,
);

const _kDialogFieldDecoration = InputDecoration(
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

class _AddMovementDialog extends StatefulWidget {
  final CategoryViewModel categoryViewModel;

  final String categoryType;

  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  const _AddMovementDialog({
    required this.categoryViewModel,
    required this.categoryType,
    required this.onSave,
    this.dateRange,
  });

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  late DateTime _selectedDate = widget.dateRange?.end ?? DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.dateRange?.start ?? DateTime(2020),
      lastDate: widget.dateRange?.end ?? DateTime.now(),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount =
        widget.categoryType == 'expense' ? -rawAmount : rawAmount;

    widget.onSave(
      CategoryPendingMovement(
        amount: signedAmount,
        type: widget.categoryType,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories
        .where((c) => c.type == widget.categoryType)
        .toList();
    final categoryTypeLabel =
        widget.categoryType == 'income' ? 'ingreso' : 'gasto';

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Agregar movimiento',
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
              const Text('Monto', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Categoría (opcional)', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              if (widget.categoryViewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (categories.isEmpty)
                Text(
                  'No hay categorías de $categoryTypeLabel todavía. '
                  'El movimiento se guardará sin categoría.',
                  style: const TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 13,
                  ),
                )
              else
                DropdownButtonFormField<Category?>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration,
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
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              const SizedBox(height: 16),
              const Text('Descripción (opcional)', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(
                  hintText: 'Ej: Retiro en efectivo',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Fecha', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _kDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _AddTransferDialog extends StatefulWidget {
  final Account currentAccount;

  final AccountViewModel accountViewModel;

  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  const _AddTransferDialog({
    required this.currentAccount,
    required this.accountViewModel,
    required this.onSave,
    this.dateRange,
  });

  @override
  State<_AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends State<_AddTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _otherAccountId;

  bool _isIncoming = true;

  late DateTime _selectedDate = widget.dateRange?.end ?? DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.dateRange?.start ?? DateTime(2020),
      lastDate: widget.dateRange?.end ?? DateTime.now(),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final otherAccountId = _otherAccountId;
    if (otherAccountId == null) return;

    final otherAccount = widget.accountViewModel.activeAccounts
        .firstWhere((a) => a.id == otherAccountId);

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount = _isIncoming ? rawAmount : -rawAmount;

    widget.onSave(
      TransferPendingMovement(
        amount: signedAmount,
        otherAccountId: otherAccount.id,
        otherAccountName: otherAccount.name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final otherAccounts = widget.accountViewModel.activeAccounts
        .where((a) => a.id != widget.currentAccount.id)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Agregar transferencia',
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
              if (otherAccounts.isEmpty)
                const Text(
                  'Necesitás al menos otra cuenta activa para cargar una '
                  'transferencia.',
                  style: TextStyle(color: AppColors.authExpense, fontSize: 13),
                )
              else ...[
                const Text('Dirección', style: _kDialogLabelStyle),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.authCardFill,
                    foregroundColor: AppColors.authTextSecondary,
                    selectedBackgroundColor: AppColors.authAccent,
                    selectedForegroundColor: AppColors.authBackgroundBottom,
                    side: const BorderSide(color: AppColors.authCardBorder),
                  ),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Entra')),
                    ButtonSegment(value: false, label: Text('Sale')),
                  ],
                  selected: {_isIncoming},
                  onSelectionChanged: (selection) =>
                      setState(() => _isIncoming = selection.first),
                ),
                const SizedBox(height: 16),
                Text(
                  _isIncoming
                      ? 'Otra cuenta (de dónde sale)'
                      : 'Otra cuenta (a dónde va)',
                  style: _kDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _otherAccountId,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration,
                  hint: const Text(
                    'Seleccioná una cuenta',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: otherAccounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _otherAccountId = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná una cuenta' : null,
                ),
                const SizedBox(height: 16),
                const Text('Monto', style: _kDialogLabelStyle),
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
                      _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                  validator: (value) {
                    final text = (value ?? '').trim().replaceAll(',', '.');
                    if (text.isEmpty) return 'Ingresa un monto';
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descripción (opcional)',
                  style: _kDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration.copyWith(
                    hintText: 'Ej: Traspaso entre cuentas propias',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Fecha', style: _kDialogLabelStyle),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _kDialogFieldDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
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
          onPressed: otherAccounts.isEmpty ? null : _save,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _SelectPendingInvoiceSheet extends StatelessWidget {
  final List<Invoice> invoices;
  final ServiceViewModel serviceViewModel;
  final String currency;

  const _SelectPendingInvoiceSheet({
    required this.invoices,
    required this.serviceViewModel,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              'Facturas pendientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay facturas pendientes para pagar.',
                  style: TextStyle(color: AppColors.authTextSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.authCardBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, i) {
                    final invoice = invoices[i];
                    final service =
                        serviceViewModel.serviceById(invoice.serviceId);
                    final serviceName = service?.name ?? 'Servicio eliminado';
                    final dueDate = invoice.dueDate;
                    final monthYear =
                        '${_kMonthAbbreviations[invoice.month - 1]} '
                        '${invoice.year}';
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(invoice),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serviceName,
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
                                    dueDate == null
                                        ? monthYear
                                        : '$monthYear · vence '
                                            '${formatMovementDate(dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.authTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(invoice.amount, currency),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.authTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final String serviceName;
  final Category category;
  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  const _AddInvoiceDialog({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.onSave,
    this.dateRange,
  });

  @override
  State<_AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<_AddInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late DateTime _selectedDate = widget.dateRange?.end ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.dateRange?.start ?? DateTime(2020),
      lastDate: widget.dateRange?.end ?? DateTime.now(),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    widget.onSave(
      InvoicePendingMovement(
        amount: -amount,
        date: _selectedDate,
        invoice: widget.invoice,
        category: widget.category,
        serviceName: widget.serviceName,
        description: 'Factura · ${widget.serviceName}',
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Pagar factura',
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
              Text(
                '${widget.serviceName} · ${widget.category.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Monto a pagar', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Fecha de pago', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _kDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style: const TextStyle(
                          color: AppColors.authTextPrimary,
                        ),
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
