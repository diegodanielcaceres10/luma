import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';

class InvoiceService {
  final SupabaseClient _client;

  InvoiceService(this._client);

  Future<List<Invoice>> fetchAll() async {
    // Vencimiento más próximo primero; las que no tienen fecha de
    // vencimiento cargada quedan al final. Entre iguales (o entre las
    // que no tienen fecha), año/mes más reciente primero.
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

  /// Edita una factura pendiente (servicio, mes, año, monto, vencimiento).
  /// No se usa sobre facturas pagadas o canceladas — la pantalla de
  /// edición no llega a mostrarse para esos casos (ver InvoicesTab).
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

  /// Cierra el flujo de una factura pendiente sin pagarla. El constraint
  /// de la tabla impide cancelar una factura ya pagada.
  Future<void> cancel({required String id}) async {
    await _client.from('invoices').update({
      'cancelled': true,
      'cancelled_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Registra el pago de una factura pendiente, vinculándola a la
  /// transacción de gasto que se creó para ese pago.
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
