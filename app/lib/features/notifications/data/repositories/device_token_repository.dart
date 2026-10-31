import '../services/device_token_service.dart';

class DeviceTokenRepository {
  final DeviceTokenService _service;

  DeviceTokenRepository(this._service);

  Future<void> register({required String token, required String platform}) =>
      _service.register(token: token, platform: platform);

  Future<void> unregister(String token) => _service.unregister(token);
}
