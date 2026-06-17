import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/app_config.dart';

/// Ottiene i token dai provider social. Usato solo se AppConfig.socialLoginEnabled.
/// Richiede la configurazione nativa (Google client id / Apple) per funzionare.
class SocialAuthService {
  // serverClientId = Web Client ID: così l'id_token ha come audience il client
  // Web, che è ciò che il backend verifica (su Android e iOS).
  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: AppConfig.googleServerClientId,
  );

  /// Ritorna l'id_token Google da inviare al backend, o null se annullato.
  Future<String?> google() async {
    // Evita lo stato "già loggato" cache lato plugin: forza la scelta account.
    await _google.signOut();
    final account = await _google.signIn();
    final auth = await account?.authentication;
    return auth?.idToken;
  }

  /// Ritorna l'identity token Apple da inviare al backend.
  Future<String?> apple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    return credential.identityToken;
  }
}
