import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Wrapper su local_auth + persistenza sicura della preferenza biometrica.
///
/// Modello di sicurezza: la biometria NON è una credenziale inviata al server.
/// Sblocca semplicemente l'uso del token Sanctum, già custodito nel Keystore/
/// Keychain del device. Senza sblocco la sessione non viene ripristinata.
class BiometricService {
  static const _enabledKey = 'snapp_biometric_enabled';
  static const _askedKey = 'snapp_biometric_asked';

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  BiometricService({LocalAuthentication? auth, FlutterSecureStorage? storage})
      : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Il device ha hardware biometrico (impronta/volto). NON richiede che una
  /// biometria sia già registrata: l'enrollment viene verificato dal sistema
  /// quando si chiama [authenticate]. Così il prompt di opt-in compare su
  /// qualunque dispositivo dotato di sensore, anche prima della registrazione.
  Future<bool> isDeviceCapable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Esiste almeno una biometria effettivamente registrata sul device.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Mostra il prompt biometrico di sistema. `true` solo se l'utente si autentica.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async => (await _storage.read(key: _enabledKey)) == 'true';

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _enabledKey, value: value ? 'true' : 'false');

  /// Se l'opt-in è già stato proposto (così non lo richiediamo a ogni accesso).
  Future<bool> wasAsked() async => (await _storage.read(key: _askedKey)) == 'true';

  Future<void> markAsked() => _storage.write(key: _askedKey, value: 'true');

  /// Reset completo: al logout non deve restare biometria senza una sessione.
  Future<void> reset() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _askedKey);
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

/// Stato del lock biometrico all'avvio:
/// - [locked]   token presente + biometria attiva → serve sblocco;
/// - [unlocked] sessione utilizzabile (nessuna biometria, oppure sbloccata);
/// - [skipped]  l'utente ha scelto di proseguire anonimo senza sbloccare
///              (il token resta, ma la sessione NON viene ripristinata).
enum BioLockState { locked, unlocked, skipped }

class AppLockController extends StateNotifier<BioLockState> {
  AppLockController(super.initial);

  void unlock() => state = BioLockState.unlocked;
  void skip() => state = BioLockState.skipped;
}

/// Valore iniziale calcolato in main() e iniettato via override del ProviderScope.
final initialBioLockStateProvider = Provider<BioLockState>((ref) => BioLockState.unlocked);

final appLockProvider = StateNotifierProvider<AppLockController, BioLockState>(
  (ref) => AppLockController(ref.read(initialBioLockStateProvider)),
);
