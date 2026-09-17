import '../models/service.dart';
import '../services/service_service.dart';

class ServiceRepository {
  final ServiceService _service;

  ServiceRepository(this._service);

  Future<List<Service>> getAll() {
    return _service.fetchAll();
  }

  Future<void> create({
    required String userId,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) {
    return _service.create(
      userId: userId,
      name: name,
      approximateAmount: approximateAmount,
      categoryId: categoryId,
      dueDay: dueDay,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) {
    return _service.update(
      id: id,
      name: name,
      approximateAmount: approximateAmount,
      categoryId: categoryId,
      dueDay: dueDay,
    );
  }

  Future<void> setActive({required String id, required bool isActive}) {
    return _service.setActive(id: id, isActive: isActive);
  }
}
