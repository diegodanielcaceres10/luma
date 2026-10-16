import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/text_action_button.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/view_models/category_view_model.dart';
import '../../../../invoices/data/models/invoice.dart';
import '../../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../../services/presentation/view_models/service_view_model.dart';
import '../../../data/models/transaction_entry.dart';

/// What the user chose to do with the movement.
enum EditMovementAction {
  /// Change category and description (the only mode for regular movements
  /// that are not converted).
  editDetails,

  /// Flag the movement as a transfer.
  convertToTransfer,

  /// Link the movement to a pending invoice as its payment.
  convertToServicePayment,

  /// Revert a service payment: the invoice goes back to pending.
  unlinkServicePayment,
}

class EditMovementResult {
  final EditMovementAction action;
  final String? categoryId;
  final String? description;

  /// Set only for [EditMovementAction.convertToServicePayment] and
  /// [EditMovementAction.unlinkServicePayment].
  final Invoice? invoice;

  const EditMovementResult({
    required this.action,
    required this.categoryId,
    required this.description,
    this.invoice,
  });
}

/// Edit dialog. Account, amount and date are never editable: the first two
/// affect `accounts.balance`.
///
/// A regular movement can have its category and description edited, or be
/// converted into a transfer or a service payment. Transfers and service
/// payments only allow editing the description.
class EditMovementDialog extends StatefulWidget {
  final TransactionEntry movement;
  final CategoryViewModel categoryViewModel;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final String currency;

  const EditMovementDialog({
    super.key,
    required this.movement,
    required this.categoryViewModel,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.currency,
  });

  @override
  State<EditMovementDialog> createState() => _EditMovementDialogState();
}

class _EditMovementDialogState extends State<EditMovementDialog> {
  late final TextEditingController _descriptionController;
  late final Invoice? _linkedInvoice;
  late final List<Invoice> _pendingInvoices;
  EditMovementAction _action = EditMovementAction.editDetails;
  Category? _selectedCategory;
  Invoice? _selectedInvoice;

  TransactionEntry get _movement => widget.movement;

  bool get _isServicePayment => _linkedInvoice != null;

  /// Transfers and service payments only allow editing the description.
  bool get _isLocked => _movement.isTransfer || _isServicePayment;

  bool get _canBeServicePayment => !_movement.isIncome;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: _movement.description ?? '',
    );
    _selectedCategory =
        widget.categoryViewModel.categoryById(_movement.category.id);
    _linkedInvoice = widget.invoiceViewModel.invoiceForTransaction(
      _movement.id,
    );
    _pendingInvoices = widget.invoiceViewModel.pendingInvoicesNear(
      _movement.date,
    );
    _selectedInvoice = _pendingInvoices.isEmpty ? null : _pendingInvoices.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? get _description {
    final text = _descriptionController.text.trim();
    return text.isEmpty ? null : text;
  }

  bool get _canConfirm {
    if (_isLocked) return true;
    return switch (_action) {
      EditMovementAction.convertToServicePayment => _selectedInvoice != null,
      _ => true,
    };
  }

  void _confirm() {
    final EditMovementResult result;

    if (_isLocked) {
      // Category is kept as is; only the description changes.
      result = EditMovementResult(
        action: EditMovementAction.editDetails,
        categoryId: _movement.category.id,
        description: _description,
      );
    } else {
      switch (_action) {
        case EditMovementAction.editDetails:
          result = EditMovementResult(
            action: _action,
            categoryId: _selectedCategory?.id,
            description: _description,
          );
        case EditMovementAction.convertToTransfer:
          result = EditMovementResult(
            action: _action,
            categoryId: null,
            description: _description,
          );
        case EditMovementAction.convertToServicePayment:
          final invoice = _selectedInvoice;
          if (invoice == null) return;
          final service = widget.serviceViewModel.serviceById(
            invoice.serviceId,
          );
          result = EditMovementResult(
            action: _action,
            // A service without category keeps the movement's own.
            categoryId: service?.categoryId ?? _movement.category.id,
            description: _description,
            invoice: invoice,
          );
        case EditMovementAction.unlinkServicePayment:
          return;
      }
    }

    Navigator.of(context).pop(result);
  }

  void _unlink() {
    final invoice = _linkedInvoice;
    if (invoice == null) return;
    Navigator.of(context).pop(
      EditMovementResult(
        action: EditMovementAction.unlinkServicePayment,
        categoryId: _movement.category.id,
        description: _movement.description,
        invoice: invoice,
      ),
    );
  }

  static const _labelStyle = TextStyle(color: AppColors.authTextSecondary);
  static const _noteStyle = TextStyle(
    color: AppColors.authTextSecondary,
    fontSize: 13,
  );

  String _invoiceLabel(Invoice invoice) {
    final service = widget.serviceViewModel.serviceById(invoice.serviceId);
    final month = invoice.month.toString().padLeft(2, '0');
    return '${service?.name ?? 'Servicio'} · $month/${invoice.year} · '
        '${formatCurrency(invoice.amount, widget.currency)}';
  }

  String get _actionHelp => switch (_action) {
        EditMovementAction.convertToTransfer =>
          'Se marcará como transferencia y se quitará la categoría. Desde '
              'acá no se puede revertir.',
        EditMovementAction.convertToServicePayment =>
          'Se registrará como el pago de la factura elegida y tomará la '
              'categoría del servicio.',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final sign = _movement.isIncome ? '+' : '-';

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Editar movimiento',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_movement.account.name} · '
              '$sign${formatCurrency(_movement.amount, widget.currency)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLocked)
              ..._buildLockedNotice()
            else ...[
              _buildActionSelector(),
              const SizedBox(height: 20),
              ..._buildActionFields(),
            ],
            InputTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hintText: 'Opcional',
            ),
            if (_isServicePayment) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextActionButton(
                  label: 'Desvincular del servicio',
                  color: AppColors.authExpense,
                  onPressed: _unlink,
                ),
              ),
              const Text(
                'La factura vuelve a quedar pendiente y el movimiento se '
                'mantiene como un gasto común.',
                style: _noteStyle,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextActionButton(
          label: 'Guardar',
          color: AppColors.authAccent,
          fontWeight: FontWeight.w700,
          onPressed: _canConfirm ? _confirm : null,
        ),
      ],
    );
  }

  List<Widget> _buildLockedNotice() {
    final invoice = _linkedInvoice;
    final text = invoice != null
        ? 'Pago de servicio: ${_invoiceLabel(invoice)}. Solo se puede editar '
            'la descripción.'
        : 'Transferencia. Solo se puede editar la descripción.';
    return [
      Text(text, style: _noteStyle),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildActionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Qué querés hacer?', style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<EditMovementAction>(
          initialValue: _action,
          dropdownColor: AppColors.authBackgroundBottom,
          style: const TextStyle(color: AppColors.authTextPrimary),
          decoration: InputTextField.formDecoration,
          items: [
            const DropdownMenuItem(
              value: EditMovementAction.editDetails,
              child: Text('Editar categoría y descripción'),
            ),
            const DropdownMenuItem(
              value: EditMovementAction.convertToTransfer,
              child: Text('Convertir en transferencia'),
            ),
            if (_canBeServicePayment)
              const DropdownMenuItem(
                value: EditMovementAction.convertToServicePayment,
                child: Text('Convertir en pago de servicio'),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _action = value);
          },
        ),
      ],
    );
  }

  List<Widget> _buildActionFields() {
    switch (_action) {
      case EditMovementAction.editDetails:
        return [..._buildCategoryField(), const SizedBox(height: 20)];
      case EditMovementAction.convertToTransfer:
        return [
          Text(_actionHelp, style: _noteStyle),
          const SizedBox(height: 20),
        ];
      case EditMovementAction.convertToServicePayment:
        return [..._buildInvoiceField(), const SizedBox(height: 20)];
      case EditMovementAction.unlinkServicePayment:
        return const [];
    }
  }

  List<Widget> _buildCategoryField() {
    final categories = widget.categoryViewModel.byType(_movement.type);
    return [
      const Text('Categoría', style: _labelStyle),
      const SizedBox(height: 8),
      if (categories.isEmpty)
        const Text(
          'No hay categorías de este tipo. Se guardará sin categoría.',
          style: TextStyle(color: AppColors.authTextSecondary),
        )
      else
        DropdownButtonFormField<Category>(
          initialValue: _selectedCategory,
          dropdownColor: AppColors.authBackgroundBottom,
          style: const TextStyle(color: AppColors.authTextPrimary),
          decoration: InputTextField.formDecoration,
          hint: const Text(
            'Sin categoría',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
          items: [
            const DropdownMenuItem<Category>(
              value: null,
              child: Text(
                'Sin categoría',
                style: TextStyle(color: AppColors.authTextSecondary),
              ),
            ),
            ...categories.map(
              (c) => DropdownMenuItem<Category>(value: c, child: Text(c.name)),
            ),
          ],
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
    ];
  }

  List<Widget> _buildInvoiceField() {
    if (_pendingInvoices.isEmpty) {
      return const [
        Text('Factura pendiente', style: _labelStyle),
        SizedBox(height: 8),
        Text('No hay facturas pendientes para vincular.', style: _noteStyle),
      ];
    }

    final invoice = _selectedInvoice;
    final differs = invoice != null && invoice.amount != _movement.amount;

    return [
      const Text('Factura pendiente', style: _labelStyle),
      const SizedBox(height: 8),
      DropdownButtonFormField<Invoice>(
        initialValue: invoice,
        isExpanded: true,
        dropdownColor: AppColors.authBackgroundBottom,
        style: const TextStyle(color: AppColors.authTextPrimary),
        decoration: InputTextField.formDecoration,
        items: [
          for (final pending in _pendingInvoices)
            DropdownMenuItem<Invoice>(
              value: pending,
              child: Text(
                _invoiceLabel(pending),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) => setState(() => _selectedInvoice = value),
      ),
      const SizedBox(height: 8),
      Text(_actionHelp, style: _noteStyle),
      if (differs) ...[
        const SizedBox(height: 8),
        const Text(
          'El monto del movimiento difiere del de la factura. El movimiento '
          'conserva su monto.',
          style: _noteStyle,
        ),
      ],
    ];
  }
}
