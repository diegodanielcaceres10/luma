import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceRepository {
  final InvoiceService _service;

  InvoiceRepository(this._service);

  Future<List<Invoice>> getAll() {
    return _service.fetchAll();
  }

  Future<void> create({
    required String userId,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) {
    return _service.create(
      userId: userId,
      serviceId: serviceId,
      month: month,
      year: year,
      amount: amount,
      dueDate: dueDate,
    );
  }

  Future<void> update({
    required String id,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) {
    return _service.update(
      id: id,
      serviceId: serviceId,
      month: month,
      year: year,
      amount: amount,
      dueDate: dueDate,
    );
  }

  Future<void> cancel(String id) {
    return _service.cancel(id: id);
  }

  Future<void> markPaid({required String id, required String transactionId}) {
    return _service.markPaid(id: id, transactionId: transactionId);
  }
}
