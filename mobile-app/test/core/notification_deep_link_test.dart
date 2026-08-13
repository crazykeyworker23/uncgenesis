import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/core/notifications/notification_service.dart';
import 'package:go_router/go_router.dart';

/// Un router de juguete con las pantallas que puede abrir un aviso.
GoRouter _router({String inicial = '/home'}) {
  Widget pantalla(String nombre) => Scaffold(body: Text(nombre));

  return GoRouter(
    initialLocation: inicial,
    routes: [
      GoRoute(path: '/home', builder: (_, __) => pantalla('Inicio')),
      GoRoute(path: '/onboarding', builder: (_, __) => pantalla('Bienvenida')),
      GoRoute(path: '/auth/login', builder: (_, __) => pantalla('Acceso')),
      GoRoute(path: '/notifications', builder: (_, __) => pantalla('Avisos')),
      GoRoute(path: '/devotionals/:slug', builder: (_, __) => pantalla('Devocional')),
      GoRoute(path: '/cells/:id', builder: (_, __) => pantalla('Célula')),
    ],
  );
}

Future<void> _montar(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

/// La pantalla que se está viendo.
///
/// `state.uri` y no `currentConfiguration.uri`: el segundo informa de la
/// pantalla base y no ve lo que se apila encima.
String _ubicacion(GoRouter router) => router.state.uri.path;

void main() {
  group('A dónde deja el aviso al tocarlo', () {
    testWidgets('abre la pantalla y deja volver', (tester) async {
      // El fallo: se usaba `go`, que reemplaza la pantalla en vez de apilarla.
      // La del aviso quedaba sola, sin flecha de volver, y el botón de atrás
      // del teléfono cerraba la aplicación.
      final router = _router();
      await _montar(tester, router);

      await NotificationService().openDeepLink('/devotionals/hebreos-13', router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/devotionals/hebreos-13');
      expect(router.canPop(), isTrue, reason: 'tiene que haber algo detrás');

      router.pop();
      await tester.pumpAndSettle();
      expect(_ubicacion(router), '/home');
    });

    testWidgets('un aviso sin destino abre el listado', (tester) async {
      final router = _router();
      await _montar(tester, router);

      await NotificationService().openDeepLink('', router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/notifications');
      expect(router.canPop(), isTrue);
    });

    testWidgets('una ruta desconocida no deja la app en un error', (tester) async {
      final router = _router();
      await _montar(tester, router);

      await NotificationService().openDeepLink('/vete-a-saber', router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/notifications');
    });

    testWidgets('estando ya en esa pantalla no se apila otra igual', (tester) async {
      // Si no, habría que volver dos veces para salir de lo mismo.
      final router = _router(inicial: '/notifications');
      await _montar(tester, router);

      await NotificationService().openDeepLink(null, router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/notifications');
      expect(router.canPop(), isFalse);
    });

    testWidgets('no interrumpe a quien todavía está iniciando sesión', (tester) async {
      final router = _router(inicial: '/auth/login');
      await _montar(tester, router);

      await NotificationService().openDeepLink('/cells/7', router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/auth/login');
    });

    testWidgets('tampoco a quien está en la bienvenida', (tester) async {
      final router = _router(inicial: '/onboarding');
      await _montar(tester, router);

      await NotificationService().openDeepLink('/devotionals/job-1', router: router);
      await tester.pumpAndSettle();

      expect(_ubicacion(router), '/onboarding');
    });
  });
}
