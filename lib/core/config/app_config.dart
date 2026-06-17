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

  /// Apple Services ID = client_id del flusso WEB (usato su Android). È anche
  /// l'audience del token Apple in quel flusso, verificata dal backend.
  static const String appleServicesId = String.fromEnvironment(
    'APPLE_SERVICES_ID',
    defaultValue: 'com.gsv.snapp.signin',
  );

  /// Return URL registrato nel Services ID Apple: il backend rimbalza i dati
  /// nell'app. DEVE coincidere con quello registrato su Apple (sempre prod).
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://snappanel.it/api/v1/auth/apple/callback',
  );

  /// OneSignal App ID. Le push si attivano quando è valorizzato (qui o via
  /// --dart-define=ONESIGNAL_APP_ID=...). Non è un segreto (la REST API Key,
  /// quella sì segreta, resta SOLO lato backend nel .env).
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );
}
