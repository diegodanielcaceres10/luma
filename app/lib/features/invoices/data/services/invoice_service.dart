import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';

class InvoiceService {
  final SupabaseClient _client;

  InvoiceService(this._client);

  Future<List<Invoice>> fetchAll() async {
    final rows = await _client
        .from('invoices')
        .select()
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (rows as List)
        .map((row) => Invoice.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Crea la factura de un servicio para un mes/año puntual. `paid` queda
  /// en false por default de la tabla — activar/pagar una factura se
  /// agrega en una etapa futura.
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
}
