/// Configurazione globale dell'app.
class AppConfig {
  /// Base URL delle API del backend.
  /// - Android emulator: usa 10.0.2.2 (alias dell'host).
  /// - Device fisico: sostituisci con l'IP del PC (es. http://192.168.x.x:8000).
  /// Override a build-time: --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
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
