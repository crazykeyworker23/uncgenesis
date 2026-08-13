/// Imágenes de la app decodificadas al tamaño en que se van a ver.
///
/// Flutter guarda en memoria el mapa de bits **a la resolución del archivo**,
/// no a la del hueco donde se dibuja. Los fondos son de 1080×2340 —unos 10 MB
/// descomprimidos cada uno— y el logotipo es de 1024×1024, o sea 4 MB, para
/// verse casi siempre a 38 puntos. Sin acotarlo, cada repintado obliga a
/// reescalar todo eso.
///
/// `cacheWidth` traslada el trabajo al momento de decodificar, una sola vez.
library;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Fondo a pantalla completa.
///
/// Se aísla en su propia capa de composición: así, cuando cambia algo por
/// delante —se abre el teclado, se escribe una letra— el sistema reutiliza la
/// capa ya pintada en lugar de rehacer la imagen entera.
///
/// Va colocado **fuera** del cuerpo del `Scaffold` en las pantallas con
/// formulario. Dentro, al abrir el teclado el cuerpo se encoge, el fondo se
/// reescala en cada fotograma de la animación y la pantalla se arrastra.
class AppBackground extends StatelessWidget {
  final String asset;
  final Alignment alignment;

  /// Velo que oscurece la foto para que el texto se lea encima.
  ///
  /// Se pinta aquí dentro, y no como un widget hermano, para que forme parte
  /// de la misma capa que la imagen. Suelto, comparte capa con el contenido de
  /// la pantalla: al abrir el teclado había que volver a mezclar el velo a
  /// pantalla completa en cada fotograma de la animación.
  final Color? overlay;

  const AppBackground(
    this.asset, {
    super.key,
    this.alignment = Alignment.center,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    // Sólo lo que se necesita. `MediaQuery.of` suscribe a todos sus cambios,
    // incluido el hueco del teclado, que se anima: el fondo se reconstruía en
    // cada fotograma de esa animación aunque no dependa de él para nada.
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            width: double.infinity,
            height: double.infinity,
            // Se decodifica al ancho real de la pantalla. En un teléfono de
            // 720 puntos de ancho son 4,5 MB en vez de 10.
            cacheWidth: (size.width * ratio).round(),
            // El fondo es decorativo: si faltara, basta el color de la
            // pantalla que hay debajo.
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          if (overlay != null) ColoredBox(color: overlay!),
        ],
      ),
    );
  }
}

/// Fondo de degradado, sin fotografía.
///
/// Para las pantallas en las que lo que se hace es escribir. Una foto a
/// pantalla completa ahí sólo cuesta: hay que decodificarla, ocupa memoria y
/// se vuelve a componer cada vez que algo cambia por delante. Un degradado lo
/// resuelve la tarjeta gráfica prácticamente gratis, y con el velo oscuro que
/// hacía falta para leer el texto encima, la foto casi no se distinguía.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkTeal, AppColors.deepTeal, AppColors.darkGreen],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Logotipo de la iglesia.
///
/// El archivo es de 1024×1024 y se usa desde 38 hasta 200 puntos. Cada sitio
/// dice a qué tamaño lo necesita y se decodifica sólo a eso.
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 38, this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);

    return Image.asset(
      'assets/logos/logo.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
      cacheWidth: (size * ratio).round(),
      errorBuilder: (_, __, ___) => Icon(
        Icons.church,
        color: color ?? AppColors.dorado,
        size: size * 0.65,
      ),
    );
  }
}
