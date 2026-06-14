import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Ottiene i token dai provider social. Usato solo se AppConfig.socialLoginEnabled.
/// Richiede la configurazione nativa (Google client id / Apple) per funzionare.
class SocialAuthService {
  final GoogleSignIn _google = GoogleSignIn(scopes: const ['email']);

  /// Ritorna l'id_token Google da inviare al backend, o null se annullato.
  Future<String?> google() async {
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
