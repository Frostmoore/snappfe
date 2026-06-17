import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/app_config.dart';

/// Esito di un login social: token da verificare lato backend + eventuale nome.
class SocialResult {
  final String token;

  /// Nome display. Apple lo fornisce SOLO al primo consenso (non è nel token),
  /// quindi va inviato al backend; per Google il nome arriva già dal token.
  final String? name;

  const SocialResult(this.token, {this.name});
}

/// Ottiene i token dai provider social. Usato solo se AppConfig.socialLoginEnabled.
/// Richiede la configurazione nativa (Google client id / Apple) per funzionare.
class SocialAuthService {
  // serverClientId = Web Client ID: così l'id_token ha come audience il client
  // Web, che è ciò che il backend verifica (su Android e iOS).
  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: AppConfig.googleServerClientId,
  );

  /// Ritorna l'id_token Google (+ nome) da inviare al backend, o null se annullato.
  Future<SocialResult?> google() async {
    // Evita lo stato "già loggato" cache lato plugin: forza la scelta account.
    await _google.signOut();
    final account = await _google.signIn();
    final auth = await account?.authentication;
    final idToken = auth?.idToken;
    if (idToken == null) return null;
    return SocialResult(idToken, name: account?.displayName);
  }

  /// Ritorna l'identity token Apple da inviare al backend.
  ///
  /// Su iOS è nativo (audience = bundle id). Su Android usa il flusso WEB:
  /// passa il Services ID + il Return URL registrato su Apple, che rimbalza i
  /// dati nell'app (audience = Services ID).
  Future<SocialResult?> apple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      webAuthenticationOptions: Platform.isIOS || Platform.isMacOS
          ? null
          : WebAuthenticationOptions(
              clientId: AppConfig.appleServicesId,
              redirectUri: Uri.parse(AppConfig.appleRedirectUri),
            ),
    );
    final token = credential.identityToken;
    if (token == null) return null;
    // Apple fornisce nome/cognome solo al primo consenso.
    final name = [credential.givenName, credential.familyName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .join(' ')
        .trim();
    return SocialResult(token, name: name.isEmpty ? null : name);
  }
}
