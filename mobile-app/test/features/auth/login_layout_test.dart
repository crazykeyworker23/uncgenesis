import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/core/providers/core_providers.dart';
import 'package:genesis_app/features/auth/presentation/pages/login_page.dart';
import 'package:go_router/go_router.dart';

import '../../views_smoke_test.dart' show FakeSecureStorage, MockAdapter;

Widget _loginHarness() {
  final dio = Dio()..options.baseUrl = 'http://localhost:8000/api/v1';
  dio.httpClientAdapter = MockAdapter();

  // Sin credenciales guardadas: si la sesión se diera por iniciada, la
  // pantalla se cerraría sola y no habría nada que medir.
  final storage = FakeSecureStorage()..data.clear();

  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWith((ref) => storage),
      dioProvider.overrideWith((ref) => dio),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/auth/login',
        routes: [GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage())],
      ),
    ),
  );
}

void main() {
  group('Acceso: el formulario se queda quieto', () {
    /// Al tocar un campo se abre el teclado. Antes el cuerpo del Scaffold se
    /// encogía y el `Center` recolocaba el formulario entero: subía de golpe,
    /// y la disposición se rehacía en cada fotograma de la animación.
    testWidgets('no se desplaza cuando aparece el teclado', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_loginHarness());
      await tester.pumpAndSettle();

      final antes = tester.getTopLeft(find.text('Iniciar sesión'));
      final correoAntes = tester.getTopLeft(find.text('Correo electrónico'));

      // Aparece el teclado, ocupando la mitad inferior.
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Iniciar sesión')), antes);
      expect(tester.getTopLeft(find.text('Correo electrónico')), correoAntes);
    });

    testWidgets('con el teclado abierto se puede desplazar hasta el pie', (tester) async {
      // El contenido ya no se recoloca, así que lo último puede quedar tapado:
      // tiene que poder alcanzarse arrastrando.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_loginHarness());
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final posicion = Scrollable.of(tester.element(find.text('Iniciar sesión'))).position;
      expect(posicion.maxScrollExtent, greaterThan(0));

      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Continuar como invitado'), findsOneWidget);
    });
  });
}
