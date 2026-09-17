import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/invoice_repository.dart';

enum InvoiceSubmitError { duplicate, generic }

class InvoiceViewModel extends ChangeNotifier {
  final InvoiceRepository _repository;
  final TransactionViewModel _transactionViewModel;

  InvoiceViewModel(this._repository, this._transactionViewModel);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  InvoiceSubmitError? _submitError;
  List<Invoice> _invoices = [];
  final Set<String> _cancellingIds = {};
  final Set<String> _payingIds = {};

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  InvoiceSubmitError? get submitError => _submitError;
  List<Invoice> get invoices => _invoices;

  bool isCancelling(String invoiceId) => _cancellingIds.contains(invoiceId);
  bool isPaying(String invoiceId) => _payingIds.contains(invoiceId);

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _repository.getAll();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar las facturas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alta de una factura. Por ahora no hay edición ni activar/inactivar
  /// — el pago (marcarla como pagada, asociarla a una transacción) se
  /// agrega en una etapa futura.
  Future<bool> createInvoice({
    required String userId,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _submitError = null;
    notifyListeners();

    try {
      await _repository.create(
        userId: userId,
        serviceId: serviceId,
        month: month,
        year: year,
        amount: amount,
        dueDate: dueDate,
      );
      await loadInvoices();
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _submitError = InvoiceSubmitError.duplicate;
        _errorMessage = 'Ya existe una factura de ese servicio para ese mes.';
      } else {
        _submitError = InvoiceSubmitError.generic;
        _errorMessage = 'No se pudo guardar la factura.';
      }
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = InvoiceSubmitError.generic;
      _errorMessage = 'No se pudo guardar la factura.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Cierra el flujo de una factura pendiente desde la lista, sin pasar
  /// por el formulario. Una factura ya pagada no llega a mostrar esta
  /// acción — la protege además el constraint de la tabla.
  Future<bool> cancelInvoice(String invoiceId) async {
    _cancellingIds.add(invoiceId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancel(invoiceId);
      await loadInvoices();
      return true;
    } catch (_) {
      _errorMessage = 'No se pudo cancelar la factura.';
      notifyListeners();
      return false;
    } finally {
      _cancellingIds.remove(invoiceId);
      notifyListeners();
    }
  }

  /// Registra el pago de una factura pendiente: crea la transacción de
  /// gasto vinculada a la categoría del servicio (con el monto que se
  /// haya confirmado, que puede diferir del importe original de la
  /// factura) y marca la factura como pagada apuntando a esa
  /// transacción. Una factura ya pagada o cancelada no llega a mostrar
  /// esta acción — la protege además el constraint de la tabla.
  ///
  /// La transacción se crea a través de [TransactionViewModel] (y no
  /// directo contra el repositorio) para que recargue sus propias listas
  /// — de lo contrario el Dashboard y Movimientos, que leen de esa misma
  /// instancia, no se enteran del gasto nuevo hasta la próxima recarga
  /// manual.
  Future<bool> payInvoice({
    required Invoice invoice,
    required String userId,
    required String accountId,
    required String categoryId,
    required double amount,
    String? description,
  }) async {
    _payingIds.add(invoice.id);
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _transactionViewModel.createTransaction(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: 'expense',
        amount: amount,
        description: description,
        date: DateTime.now(),
      );
      final transactionId = _transactionViewModel.lastCreatedTransactionId;
      if (!created || transactionId == null) {
        _errorMessage = _transactionViewModel.errorMessage ??
            'No se pudo registrar el pago.';
        notifyListeners();
        return false;
      }

      await _repository.markPaid(
        id: invoice.id,
        transactionId: transactionId,
      );
      await loadInvoices();
      return true;
    } catch (_) {
      _errorMessage = 'No se pudo registrar el pago.';
      notifyListeners();
      return false;
    } finally {
      _payingIds.remove(invoice.id);
      notifyListeners();
    }
  }
}
