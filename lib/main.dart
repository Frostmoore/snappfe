import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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

  runApp(const ProviderScope(child: SnappApp()));
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
      builder: (context, child) =>
          MediaQuery.withNoTextScaling(child: child ?? const SizedBox.shrink()),
    );
  }
}
