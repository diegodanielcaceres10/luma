import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class ServiceService {
  final SupabaseClient _client;

  ServiceService(this._client);

  Future<List<Service>> fetchAll() async {
    // Trae activos e inactivos: la lista de servicios es donde se
    // inactivan/reactivan, así que necesita ver ambos estados.
    final rows = await _client.from('services').select().order('name');

    return (rows as List)
        .map((row) => Service.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String userId,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) async {
    await _client.from('services').insert({
      'user_id': userId,
      'name': name,
      'approximate_amount': approximateAmount,
      'category_id': categoryId,
      'due_day': dueDay,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) async {
    await _client.from('services').update({
      'name': name,
      'approximate_amount': approximateAmount,
      'category_id': categoryId,
      'due_day': dueDay,
    }).eq('id', id);
  }

  /// Activa o inactiva un servicio desde la lista, sin pasar por el
  /// formulario completo.
  Future<void> setActive({required String id, required bool isActive}) async {
    await _client
        .from('services')
        .update({'is_active': isActive}).eq('id', id);
  }
}
