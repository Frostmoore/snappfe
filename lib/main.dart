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

class SnappApp extends StatefulWidget {
  const SnappApp({super.key});

  @override
  State<SnappApp> createState() => _SnappAppState();
}

class _SnappAppState extends State<SnappApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A ogni ritorno in primo piano: verifica che le push siano davvero attive
    // (consenso dato ma device non iscritto → ritenta). Auto-riparazione.
    if (state == AppLifecycleState.resumed) {
      PushService.ensureSubscribed();
    }
  }

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
