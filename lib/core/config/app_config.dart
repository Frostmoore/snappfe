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

  /// Login social attivo solo quando configurate le credenziali Google/Apple.
  static const bool socialLoginEnabled = bool.fromEnvironment(
    'SOCIAL_ENABLED',
    defaultValue: false,
  );

  /// Push attive solo quando configurato Firebase (google-services.json).
  static const bool pushEnabled = bool.fromEnvironment(
    'PUSH_ENABLED',
    defaultValue: false,
  );
}
