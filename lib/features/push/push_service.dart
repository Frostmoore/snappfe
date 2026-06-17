import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';

/// Servizio notifiche push basato su **OneSignal**.
///
/// Il targeting lato backend è per **external user id** = id utente app: dopo il
/// login chiamiamo `OneSignal.login(userId)`, così il backend può colpire il
/// singolo utente (o un livello/segmento). Le push sono attive solo se
/// `ONESIGNAL_APP_ID` è configurato (vedi [AppConfig.oneSignalAppId]); senza,
/// tutti i metodi sono no-op e l'app gira lo stesso.
class PushService {
  static bool get _enabled => AppConfig.oneSignalAppId.isNotEmpty;

  static Future<void> init() async {
    if (!_enabled) return;
    OneSignal.initialize(AppConfig.oneSignalAppId);
    // Apertura della notifica → instradamento del deep-link nell'app.
    OneSignal.Notifications.addClickListener(_onClick);
    // Permesso notifiche (iOS sempre; Android 13+).
    await OneSignal.Notifications.requestPermission(true);
  }

  /// Associa il device all'utente app (external id) per il targeting per-utente.
  static Future<void> login(String externalId) async {
    if (!_enabled || externalId.isEmpty) return;
    await OneSignal.login(externalId);
  }

  /// Sgancia l'utente al logout: il device non riceve più push mirate all'utente.
  static Future<void> logout() async {
    if (!_enabled) return;
    await OneSignal.logout();
  }

  /// Al tap sulla notifica instrada il deep-link (`data.deep_link`) nel router.
  static void _onClick(OSNotificationClickEvent event) {
    final raw = event.notification.additionalData?['deep_link'];
    if (raw is! String || raw.isEmpty) return;

    // Accetta sia un path ("/articles/5") sia uno schema ("snapp://articles/5").
    var path = raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      path = uri.path.isEmpty ? '/' : uri.path;
      if (uri.hasQuery) path += '?${uri.query}';
    }
    goRouter.go(path);
  }
}
