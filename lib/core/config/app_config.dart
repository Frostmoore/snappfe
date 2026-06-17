/// Configurazione globale dell'app.
class AppConfig {
  /// Base URL delle API del backend. Default: **produzione** (snappanel.it).
  /// Per puntare al backend locale in dev:
  ///   --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1  (emulatore Android)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://snappanel.it/api/v1',
  );

  /// Schema deep-link dell'app (vedi backend Appendice A).
  static const String deepLinkScheme = 'snapp';

  /// Login social attivo (Google reale; Apple in arrivo). Si può disattivare
  /// per tornare al flusso mock con --dart-define=SOCIAL_ENABLED=false.
  static const bool socialLoginEnabled = bool.fromEnvironment(
    'SOCIAL_ENABLED',
    defaultValue: true,
  );

  /// "Server client ID" Google = il **Web** Client ID del progetto Google Cloud.
  /// È l'audience dell'id_token: il backend verifica che combaci. Non è un segreto
  /// (i Client ID sono pubblici); il secret resta solo lato server nel .env.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '572671763940-jgf9qtmebnkg1tj5s4lds73h5n626s01.apps.googleusercontent.com',
  );

  /// Push attive solo quando configurato Firebase (google-services.json).
  static const bool pushEnabled = bool.fromEnvironment(
    'PUSH_ENABLED',
    defaultValue: false,
  );
}
