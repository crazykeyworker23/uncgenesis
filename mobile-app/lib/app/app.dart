import 'package:flutter/material.dart';
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
      routerConfig: appRouter,
    );
  }
}
