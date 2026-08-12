import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/core/widgets/app_images.dart';

/// Ancho al que se guardará el mapa de bits, o `null` si se decodifica entero.
int? _decodedWidth(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  final provider = image.image;
  return provider is ResizeImage ? provider.width : null;
}

void main() {
  group('Logotipo', () {
    testWidgets('se decodifica al tamaño en que se ve, no al del archivo', (tester) async {
      // El archivo es de 1024x1024: decodificarlo entero son 4 MB en memoria
      // para dibujar un icono de 38 puntos, y hay que reescalarlo en cada
      // repintado.
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLogo(size: 38))),
      );

      expect(_decodedWidth(tester), 114); // 38 puntos x 3
    });

    testWidgets('respeta la densidad de la pantalla', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLogo(size: 200))),
      );

      expect(_decodedWidth(tester), 400);
    });
  });

  group('Fondo a pantalla completa', () {
    testWidgets('se decodifica al ancho real de la pantalla', (tester) async {
      // En un teléfono de 360 puntos a 2x son 720 pixeles: 4,5 MB en vez de
      // los 10 que ocupa el archivo de 1080x2340.
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(720, 1560);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppBackground('assets/images/splash_bg.png')),
        ),
      );

      expect(_decodedWidth(tester), 720);
    });

    testWidgets('queda aislado en su propia capa', (tester) async {
      // Sin esto, cualquier cambio por delante —abrir el teclado, escribir una
      // letra— obliga a recomponer la imagen entera.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppBackground('assets/images/splash_bg.png')),
        ),
      );

      expect(
        find.ancestor(of: find.byType(Image), matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
    });

    testWidgets('el velo oscuro viaja dentro de esa misma capa', (tester) async {
      // Suelto, como widget hermano, comparte capa con el contenido de la
      // pantalla: al abrir el teclado había que volver a mezclarlo a pantalla
      // completa en cada fotograma de la animación.
      const velo = Color(0x99032F2F);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBackground('assets/images/splash_bg.png', overlay: velo),
          ),
        ),
      );

      final coloredBox = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == velo,
      );
      expect(coloredBox, findsOneWidget);
      expect(
        find.ancestor(of: coloredBox, matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
    });

    testWidgets('sin velo no se pinta una capa de más', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppBackground('assets/images/splash_bg.png')),
        ),
      );

      // El Scaffold pinta su propio color de fondo, así que se mira sólo
      // dentro del widget.
      expect(
        find.descendant(of: find.byType(AppBackground), matching: find.byType(ColoredBox)),
        findsNothing,
      );
    });
  });
}
