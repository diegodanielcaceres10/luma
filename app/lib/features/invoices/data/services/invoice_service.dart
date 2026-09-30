import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';

class InvoiceService {
  final SupabaseClient _client;

  InvoiceService(this._client);

  Future<List<Invoice>> fetchAll() async {
    // Nearest due date first, invoices without one last; ties broken by
    // most recent year/month.
    final rows = await _client
        .from('invoices')
        .select()
        .order('due_date', ascending: true, nullsFirst: false)
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (rows as List)
        .map((row) => Invoice.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates a service's invoice for a given month/year. `paid` defaults to
  /// false in the table.
  Future<void> create({
    required String userId,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) async {
    await _client.from('invoices').insert({
      'user_id': userId,
      'service_id': serviceId,
      'month': month,
      'year': year,
      'amount': amount,
      'due_date': dueDate == null
          ? null
          : '${dueDate.year.toString().padLeft(4, '0')}-'
              '${dueDate.month.toString().padLeft(2, '0')}-'
              '${dueDate.day.toString().padLeft(2, '0')}',
    });
  }

  /// Pending invoices due exactly today (device local date), used by the
  /// daily notifications routine (`NotificationSchedulerService`). It does
  /// not filter by user because RLS (`auth.uid() = user_id`) already does.
  Future<List<Invoice>> fetchDueToday() async {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('invoices')
        .select()
        .eq('due_date', today)
        .eq('paid', false)
        .eq('cancelled', false);

    return (rows as List)
        .map((row) => Invoice.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Edits a pending invoice (service, month, year, amount, due date). Not
  /// used for paid or cancelled invoices: the view screen does not offer it.
  Future<void> update({
    required String id,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) async {
    await _client.from('invoices').update({
      'service_id': serviceId,
      'month': month,
      'year': year,
      'amount': amount,
      'due_date': dueDate == null
          ? null
          : '${dueDate.year.toString().padLeft(4, '0')}-'
              '${dueDate.month.toString().padLeft(2, '0')}-'
              '${dueDate.day.toString().padLeft(2, '0')}',
    }).eq('id', id);
  }

  /// Closes a pending invoice without paying it. A table constraint prevents
  /// cancelling an already paid invoice.
  Future<void> cancel({required String id}) async {
    await _client.from('invoices').update({
      'cancelled': true,
      'cancelled_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Marks a pending invoice as paid, linking it to the expense transaction
  /// created for that payment.
  Future<void> markPaid({
    required String id,
    required String transactionId,
  }) async {
    await _client.from('invoices').update({
      'paid': true,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
      'transaction_id': transactionId,
    }).eq('id', id);
  }
}
