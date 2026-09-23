import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/parent_access_service.dart';

class SecureParentCredentialStore implements ParentCredentialStore {
  SecureParentCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _pinKey = 'parent_access_pin';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearPin() => _storage.delete(key: _pinKey);

  @override
  Future<String?> readPin() => _storage.read(key: _pinKey);

  @override
  Future<void> savePin(String pin) => _storage.write(key: _pinKey, value: pin);
}
