abstract interface class ParentCredentialStore {
  Future<void> savePin(String pin);

  Future<String?> readPin();

  Future<void> clearPin();
}

abstract interface class ParentBiometricAuthenticator {
  Future<bool> isAvailable();

  Future<bool> authenticate();
}

class ParentAccessService {
  ParentAccessService(this._credentialStore, this._biometricAuthenticator);

  final ParentCredentialStore _credentialStore;
  final ParentBiometricAuthenticator _biometricAuthenticator;

  static bool isValidPinFormat(String pin) =>
      RegExp(r'^\d{4,6}$').hasMatch(pin);

  Future<bool> hasPin() async => await _credentialStore.readPin() != null;

  Future<bool> setPin(String pin) async {
    if (!isValidPinFormat(pin)) return false;
    await _credentialStore.savePin(pin);
    return true;
  }

  Future<bool> verifyPin(String candidate) async {
    if (!isValidPinFormat(candidate)) return false;
    final stored = await _credentialStore.readPin();
    return stored != null && stored == candidate;
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await verifyPin(currentPin) || !isValidPinFormat(newPin)) {
      return false;
    }
    await _credentialStore.savePin(newPin);
    return true;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _biometricAuthenticator.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _biometricAuthenticator.authenticate();
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() => _credentialStore.clearPin();
}

class MemoryParentCredentialStore implements ParentCredentialStore {
  String? _pin;

  @override
  Future<void> clearPin() async => _pin = null;

  @override
  Future<String?> readPin() async => _pin;

  @override
  Future<void> savePin(String pin) async => _pin = pin;
}

class UnavailableParentBiometricAuthenticator
    implements ParentBiometricAuthenticator {
  const UnavailableParentBiometricAuthenticator();

  @override
  Future<bool> authenticate() async => false;

  @override
  Future<bool> isAvailable() async => false;
}
