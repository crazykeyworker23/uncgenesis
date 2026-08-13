import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/core_providers.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Un solo contenedor para toda la app.
  //
  // Antes se creaba aquí un `ApiClient` suelto para el servicio de
  // notificaciones, y las pantallas usaban otro distinto, el de Riverpod. Dos
  // clientes contra la misma sesión, cada uno con su propio control de
  // refresco, y el suelto además sin avisar a nadie cuando la daba por
  // perdida. Con esto los dos caminos comparten el mismo cliente.
  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GenesisApp(),
    ),
  );

  // Non-blocking background initialization so the app renders immediately (0ms)
  Future.microtask(() async {
    try {
      await ApiClient.determineBaseUrl();
      // Se lee `authProvider` antes de entregar el cliente: es quien engancha
      // el aviso de sesión caducada. Si el servicio de notificaciones tropieza
      // con un token muerto antes de eso, la sesión se borraría en silencio y
      // la app seguiría creyendo que sigue abierta.
      container.read(authProvider);
      await NotificationService().initialize(
        apiClient: container.read(apiClientProvider),
        navKey: rootNavigatorKey,
      );
    } catch (_) {}
  });
}
