import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/invoice_repository.dart';

enum InvoiceSubmitError { duplicate, generic }

class InvoiceViewModel extends ChangeNotifier {
  final InvoiceRepository _repository;

  InvoiceViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  InvoiceSubmitError? _submitError;
  List<Invoice> _invoices = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  InvoiceSubmitError? get submitError => _submitError;
  List<Invoice> get invoices => _invoices;

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
}
