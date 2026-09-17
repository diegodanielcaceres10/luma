import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

enum ServiceSubmitError { duplicate, generic }

class ServiceViewModel extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  ServiceSubmitError? _submitError;
  List<Service> _services = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ServiceSubmitError? get submitError => _submitError;
  List<Service> get services => _services;

  /// Servicios activos — para elegir servicio al generar una factura del
  /// mes. La lista completa (con inactivos) se usa solo en la pantalla
  /// "Servicios", donde se pueden reactivar.
  List<Service> get activeServices =>
      _services.where((service) => service.isActive).toList();

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _repository.getAll();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar los servicios.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createService({
    required String userId,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          approximateAmount: approximateAmount,
          categoryId: categoryId,
          dueDay: dueDay,
        ));
  }

  Future<bool> updateService({
    required String id,
    required String name,
    required double approximateAmount,
    String? categoryId,
    int? dueDay,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
          approximateAmount: approximateAmount,
          categoryId: categoryId,
          dueDay: dueDay,
        ));
  }

  /// Inactiva o reactiva un servicio desde la lista.
  Future<bool> toggleActive(String id, bool isActive) async {
    return _submit(
      () => _repository.setActive(id: id, isActive: isActive),
    );
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    _submitError = null;
    notifyListeners();

    try {
      await action();
      await loadServices();
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _submitError = ServiceSubmitError.duplicate;
        _errorMessage = 'Ya existe un servicio con ese nombre.';
      } else {
        _submitError = ServiceSubmitError.generic;
        _errorMessage = 'No se pudo guardar el servicio.';
      }
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = ServiceSubmitError.generic;
      _errorMessage = 'No se pudo guardar el servicio.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
