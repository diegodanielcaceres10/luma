import '../models/transaction_entry.dart';
import '../services/transaction_service.dart';

class TransactionRepository {
  final TransactionService _service;

  TransactionRepository(this._service);

  Future<List<TransactionEntry>> getForMonth(DateTime month) {
    return _service.fetchForMonth(month);
  }

  Future<List<TransactionEntry>> getAll() {
    return _service.fetchAll();
  }

  Future<String> create({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    bool isTransfer = false,
  }) {
    return _service.createTransaction(
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      isTransfer: isTransfer,
    );
  }
}
