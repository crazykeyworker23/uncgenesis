import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'session_sync.dart';
import 'theme/app_theme.dart';

class GenesisApp extends ConsumerWidget {
  const GenesisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene vivo el sincronizador de sesión durante toda la vida de la app:
    // refresca los datos dependientes del usuario al entrar y salir de sesión.
    ref.watch(sessionSyncProvider);

    return MaterialApp.router(
      title: 'Génesis App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Toda la app está escrita en español; los diálogos que aporta Flutter
      // —el calendario y el reloj al registrar una reunión— deben hablarlo
      // también.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
