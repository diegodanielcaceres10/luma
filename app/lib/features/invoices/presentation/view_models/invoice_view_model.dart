import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/data/models/service.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/invoice_repository.dart';

enum InvoiceSubmitError { duplicate, generic }

class InvoiceViewModel extends ChangeNotifier {
  final InvoiceRepository _repository;
  final TransactionViewModel _transactionViewModel;

  InvoiceViewModel(this._repository, this._transactionViewModel);

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  InvoiceSubmitError? _submitError;
  List<Invoice> _invoices = [];
  final Set<String> _cancellingIds = {};
  final Set<String> _payingIds = {};

  bool get isLoading => _isLoading;

  /// `true` una vez que la lista se cargó con éxito al menos una vez. Sirve
  /// para distinguir "todavía no llegaron" de "llegaron y esta no existe"
  /// (ver EntityRouteGuard, usado por `/invoices/:id/edit`).
  bool get hasLoaded => _hasLoaded;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  InvoiceSubmitError? get submitError => _submitError;
  List<Invoice> get invoices => _invoices;

  /// Cantidad de facturas pendientes (ni pagadas ni canceladas). Se usa,
  /// por ejemplo, como badge en el acceso rápido del Dashboard.
  int get pendingCount => _invoices.where((i) => i.isPending).length;

  bool isCancelling(String invoiceId) => _cancellingIds.contains(invoiceId);
  bool isPaying(String invoiceId) => _payingIds.contains(invoiceId);

  /// Lo que falta pagar este mes por servicios recurrentes, para el
  /// BalanceCard del Dashboard: de los [activeServices] recibidos, deja
  /// afuera los que ya tengan su factura del mes pagada o cancelada, y
  /// suma el resto — el monto de la factura pendiente si ya se generó, o
  /// el aproximado del servicio si todavía no existe factura para este
  /// mes.
  double pendingAmountForCurrentMonth(List<Service> activeServices) {
    final now = DateTime.now();
    var total = 0.0;

    for (final service in activeServices) {
      Invoice? invoiceThisMonth;
      for (final invoice in _invoices) {
        if (invoice.serviceId == service.id &&
            invoice.month == now.month &&
            invoice.year == now.year) {
          invoiceThisMonth = invoice;
          break;
        }
      }

      if (invoiceThisMonth == null) {
        total += service.approximateAmount;
      } else if (invoiceThisMonth.isPending) {
        total += invoiceThisMonth.amount;
      }
      // Pagada o cancelada: no suma, ya está resuelta para este mes.
    }

    return total;
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _repository.getAll();
      _hasLoaded = true;
    } catch (error) {
      _errorMessage = 'No se pudieron cargar las facturas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alta de una factura. Activar/inactivar (marcarla pagada) se maneja
  /// aparte, desde la lista — ver [payInvoice] y [cancelInvoice].
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

  /// Edita una factura pendiente (servicio, mes, año, monto, vencimiento).
  /// Solo aplica a pendientes — una factura pagada o cancelada no llega a
  /// mostrar esta acción (ver InvoicesTab).
  Future<bool> updateInvoice({
    required String id,
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
      await _repository.update(
        id: id,
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
  /// factura, y la fecha elegida en el diálogo de pago — si no se pasa
  /// ninguna, se usa la fecha actual) y marca la factura como pagada
  /// apuntando a esa transacción. Una factura ya pagada o cancelada no
  /// llega a mostrar esta acción — la protege además el constraint de la
  /// tabla.
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
    DateTime? date,
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
        date: date ?? DateTime.now(),
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
