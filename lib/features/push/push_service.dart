import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Imposta (o rimuove) il tag `wp_role` sul device: serve a OneSignal per i
  /// segmenti/filtri per ruolo WordPress. Il targeting per ruolo dal pannello
  /// usa comunque l'external_id lato server; il tag abilita i segmenti OneSignal.
  static void setRole(String? wpRole) {
    if (!_enabled) return;
    if (wpRole != null && wpRole.isNotEmpty) {
      OneSignal.User.addTags({'wp_role': wpRole});
    } else {
      OneSignal.User.removeTag('wp_role');
    }
  }

  /// Registra l'email dell'utente come email subscription OneSignal (consente
  /// l'invio email via OneSignal e l'aggancio dell'email all'utente).
  static void setEmail(String? email) {
    if (!_enabled || email == null || email.isEmpty) return;
    OneSignal.User.addEmail(email);
  }

  /// Sgancia l'utente al logout: il device non riceve più push mirate all'utente.
  static Future<void> logout() async {
    if (!_enabled) return;
    await OneSignal.logout();
  }

  /// Al tap sulla notifica gestisce il campo `data.deep_link`:
  /// - http/https → apre il **link esterno** nel browser;
  /// - altrimenti → **deep-link interno**, naviga nel router (accetta sia
  ///   "/articles/5" sia "snapp://articles/5").
  static Future<void> _onClick(OSNotificationClickEvent event) async {
    final raw = event.notification.additionalData?['deep_link'];
    if (raw is! String || raw.isEmpty) return;

    final uri = Uri.tryParse(raw);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    var path = raw;
    if (uri != null && uri.hasScheme) {
      path = uri.path.isEmpty ? '/' : uri.path;
      if (uri.hasQuery) path += '?${uri.query}';
    }
    goRouter.go(path);
  }
}
