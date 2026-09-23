import 'package:local_auth/local_auth.dart';

import '../domain/parent_access_service.dart';

class LocalParentBiometricAuthenticator
    implements ParentBiometricAuthenticator {
  LocalParentBiometricAuthenticator({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isAvailable() async {
    if (!await _authentication.canCheckBiometrics) return false;
    return (await _authentication.getAvailableBiometrics()).isNotEmpty;
  }

  @override
  Future<bool> authenticate() {
    return _authentication.authenticate(
      localizedReason: 'Подтвердите вход в раздел для родителей',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}
