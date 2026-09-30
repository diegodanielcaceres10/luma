import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

enum ServiceSubmitError { duplicate, generic }

class ServiceViewModel extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceViewModel(this._repository);

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  ServiceSubmitError? _submitError;
  List<Service> _services = [];

  bool get isLoading => _isLoading;

  /// `true` once the list has loaded successfully at least once, to tell
  /// "not loaded yet" apart from "loaded and missing" (see EntityRouteGuard).
  bool get hasLoaded => _hasLoaded;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ServiceSubmitError? get submitError => _submitError;
  List<Service> get services => _services;

  /// Active services, to pick from when generating the month's invoice. The
  /// full list (including inactive) is only used by the service screens.
  List<Service> get activeServices =>
      _services.where((service) => service.isActive).toList();

  /// Looks up a service by id, for features that only store `service_id`.
  Service? serviceById(String? id) {
    if (id == null) return null;
    for (final service in _services) {
      if (service.id == id) return service;
    }
    return null;
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _repository.getAll();
      // Postgres `order('name')` is case-sensitive; re-sort ignoring case
      // (same as AccountViewModel.loadAccounts).
      _services.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _hasLoaded = true;
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

  /// Deactivates or reactivates a service from the view screen.
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
