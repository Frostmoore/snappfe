import '../../core/config/app_config.dart';

/// Servizio notifiche push.
///
/// STUB finché Firebase non è configurato (`AppConfig.pushEnabled`).
/// Quando attivo, l'implementazione dovrà:
///  1. inizializzare firebase_core + firebase_messaging;
///  2. registrare il token FCM con `POST /api/v1/devices`;
///  3. al tap sulla notifica, leggere `data['deep_link']` e instradarlo al router
///     (schema `snapp://...`, vedi AppConfig.deepLinkScheme).
class PushService {
  static Future<void> init() async {
    if (!AppConfig.pushEnabled) {
      return; // push non attive finché Firebase non è configurato
    }
    // TODO: integrazione firebase_messaging + registrazione device + deep-link.
  }
}
