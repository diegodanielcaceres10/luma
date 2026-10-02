import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_clock.dart';
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

  /// `true` once the list has loaded successfully at least once, to tell
  /// "not loaded yet" apart from "loaded and missing" (see EntityRouteGuard).
  bool get hasLoaded => _hasLoaded;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  InvoiceSubmitError? get submitError => _submitError;
  List<Invoice> get invoices => _invoices;

  /// Number of pending invoices, e.g. for the Dashboard quick-access badge.
  int get pendingCount => _invoices.where((i) => i.isPending).length;

  /// Number of pending invoices for the current month, used by the
  /// Dashboard BalanceCard.
  int get pendingCountForCurrentMonth {
    final now = nowLocal();
    return _invoices
        .where((i) => i.isPending && i.month == now.month && i.year == now.year)
        .length;
  }

  bool isCancelling(String invoiceId) => _cancellingIds.contains(invoiceId);
  bool isPaying(String invoiceId) => _payingIds.contains(invoiceId);

  /// Amount still to pay this month for recurring services (Dashboard
  /// BalanceCard). Skips [activeServices] whose invoice for this month is
  /// paid or cancelled; for the rest it adds the pending invoice amount, or
  /// the service's approximate amount if no invoice exists yet.
  double pendingAmountForCurrentMonth(List<Service> activeServices) {
    final now = nowLocal();
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
      // Paid or cancelled: already resolved for this month.
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

  /// Paying and cancelling are handled separately: see [payInvoice] and
  /// [cancelInvoice].
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

  /// Edits a pending invoice. Paid or cancelled invoices cannot be edited.
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

  /// Closes a pending invoice without paying it. Paid invoices are also
  /// protected by a table constraint.
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

  /// Pays a pending invoice: creates the expense transaction linked to the
  /// service's category (with the confirmed amount, which may differ from
  /// the invoice amount, on the chosen date, defaulting to today) and marks
  /// the invoice as paid pointing to that transaction. Paid or cancelled
  /// invoices are also protected by a table constraint.
  ///
  /// The transaction goes through [TransactionViewModel] (not the repository)
  /// so it reloads its own lists; otherwise the Dashboard and Movements
  /// would not see the new expense until a manual reload.
  ///
  /// With [justifying] (month and year of the opening balance being
  /// justified) the expense is registered as a justifying transaction: it
  /// does not move `accounts.balance` and is only discounted from
  /// `uncontrolled_expenses_total`.
  Future<bool> payInvoice({
    required Invoice invoice,
    required String userId,
    required String accountId,
    required String categoryId,
    required double amount,
    String? description,
    DateTime? date,
    ({int month, int year})? justifying,
  }) async {
    _payingIds.add(invoice.id);
    _errorMessage = null;
    notifyListeners();

    try {
      final paymentDate = date ?? nowLocal();
      final created = justifying == null
          ? await _transactionViewModel.createTransaction(
              userId: userId,
              accountId: accountId,
              categoryId: categoryId,
              type: 'expense',
              amount: amount,
              description: description,
              date: paymentDate,
            )
          : await _transactionViewModel.createJustifyingTransaction(
              userId: userId,
              accountId: accountId,
              categoryId: categoryId,
              type: 'expense',
              amount: amount,
              description: description,
              date: paymentDate,
              month: justifying.month,
              year: justifying.year,
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
