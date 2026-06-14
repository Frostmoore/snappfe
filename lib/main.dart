import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/auth/biometric_service.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/unlock_screen.dart';
import 'features/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log degli errori a console (visibili in logcat / flutter run).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM_ERROR: $error\n$stack');
    return true;
  };

  try {
    await initializeDateFormatting('it', null);
  } catch (e, s) {
    debugPrint('INIT_DATE_ERROR: $e\n$s');
  }
  await PushService.init();

  // Stato di lock iniziale: se esiste un token salvato E la biometria è attiva,
  // l'app parte BLOCCATA e richiede lo sblocco prima di ripristinare la sessione.
  BioLockState initialLock = BioLockState.unlocked;
  try {
    final token = await TokenStorage().read();
    final biometricEnabled = await BiometricService().isEnabled();
    if (token != null && biometricEnabled) {
      initialLock = BioLockState.locked;
    }
  } catch (e, s) {
    debugPrint('INIT_LOCK_ERROR: $e\n$s');
  }

  runApp(ProviderScope(
    overrides: [initialBioLockStateProvider.overrideWithValue(initialLock)],
    child: const SnappApp(),
  ));
}

class SnappApp extends StatelessWidget {
  const SnappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SNAPP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: goRouter,
      // Testi a dimensione fissa, indipendenti dall'impostazione font del sistema.
      // Il gate biometrico sovrappone la schermata di sblocco quando necessario.
      builder: (context, child) => AppLockGate(
        child: MediaQuery.withNoTextScaling(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
