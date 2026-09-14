import '../models/transaction_entry.dart';
import '../services/transaction_service.dart';

class TransactionRepository {
  final TransactionService _service;

  TransactionRepository(this._service);

  Future<List<TransactionEntry>> getForMonth(DateTime month) {
    return _service.fetchForMonth(month);
  }
}
