import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/storage/token_storage.dart';
import '../push/push_service.dart';

/// Utente autenticato.
class User {
  final int id;
  final String name;
  final String email;
  final String role; // ruolo app (permessi): member/staff/admin/superadmin
  final String? membershipLevel;
  final String? wpRole; // ruolo SNA esatto dal sito (slug)
  final String? wpRoleLabel; // ruolo SNA esatto dal sito (nome)
  final bool emailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.membershipLevel,
    this.wpRole,
    this.wpRoleLabel,
    required this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'member') as String,
        membershipLevel: j['membership_level'] as String?,
        wpRole: j['wp_role'] as String?,
        wpRoleLabel: j['wp_role_label'] as String?,
        emailVerified: (j['email_verified'] ?? false) as bool,
      );

  bool get isLinked => membershipLevel != null;
}

class AuthRepository {
  final ApiClient api;
  final TokenStorage tokenStorage;

  AuthRepository(this.api, this.tokenStorage);

  Future<User> _authResult(dynamic data) async {
    final map = Map<String, dynamic>.from(data as Map);
    await tokenStorage.write(map['token'] as String);
    return User.fromJson(Map<String, dynamic>.from(map['user'] as Map));
  }

  Future<User> login(String email, String password) async {
    final data = await api.postData('/auth/login', body: {
      'email': email,
      'password': password,
      'device_name': 'mobile',
    });
    return _authResult(data);
  }

  Future<User> register(String name, String email, String password, String passwordConfirmation) async {
    final data = await api.postData('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return _authResult(data);
  }

  Future<User> socialLogin(String provider, String token, {String? name}) async {
    final data = await api.postData('/auth/social/$provider', body: {
      'token': token,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return _authResult(data);
  }

  /// Accesso con le credenziali del sito SNA: crea/trova l'utente e lo collega
  /// direttamente all'account WordPress.
  Future<User> snaLogin(String identifier, String password) async {
    final data = await api.postData('/auth/sna', body: {
      'identifier': identifier,
      'password': password,
      'device_name': 'mobile',
    });
    return _authResult(data);
  }

  Future<User> me() async {
    final data = await api.getData('/me');
    return User.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> forgotPassword(String email) async {
    await api.postData('/auth/password/forgot', body: {'email': email});
  }

  /// Reinvia l'email di verifica all'utente autenticato (token già presente).
  Future<void> resendVerification() async {
    await api.postData('/auth/verify/resend');
  }

  /// Conferma la password dell'utente corrente (fallback alla biometria).
  /// Lancia ApiException se errata.
  Future<void> confirmPassword(String password) async {
    await api.postData('/auth/password/confirm', body: {'password': password});
  }

  Future<void> logout() async {
    try {
      await api.postData('/auth/logout');
    } catch (_) {}
    await tokenStorage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider), ref.read(tokenStorageProvider)),
);

/// Sessione: null = anonimo. Caricata all'avvio dal token salvato.
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return null;

    // La sessione viene ripristinata normalmente all'avvio. La biometria NON
    // blocca tutta l'app: protegge solo l'area riservata (vedi AccountGate).
    try {
      final user = await ref.read(authRepositoryProvider).me();
      await PushService.login(user.id.toString()); // identità OneSignal
      PushService.setRole(user.wpRole); // tag ruolo WP per i segmenti
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token non valido (es. revocato/scaduto, o di un altro backend):
        // pulisci la sessione E disattiva la biometria — non ha senso bloccare
        // una sessione inesistente.
        await ref.read(tokenStorageProvider).clear();
        await ref.read(biometricServiceProvider).reset();
      }
      // Altri errori HTTP: non cancellare il token.
      return null;
    } catch (_) {
      // Errore di rete/offline: NON cancellare il token, si riproverà.
      return null;
    }
  }

  /// Allinea l'identità push (OneSignal) all'utente corrente dopo ogni auth.
  Future<void> _syncPush() async {
    final user = state.value;
    if (user != null) {
      await PushService.login(user.id.toString());
      PushService.setRole(user.wpRole);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(email, password));
    await _syncPush();
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(name, email, password, passwordConfirmation),
    );
    await _syncPush();
  }

  Future<void> socialLogin(String provider, String token, {String? name}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).socialLogin(provider, token, name: name));
    await _syncPush();
  }

  Future<void> snaLogin(String identifier, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).snaLogin(identifier, password));
    await _syncPush();
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    // Senza sessione non deve restare attiva alcuna preferenza biometrica.
    await ref.read(biometricServiceProvider).reset();
    await PushService.logout(); // sgancia l'identità OneSignal
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).me());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
