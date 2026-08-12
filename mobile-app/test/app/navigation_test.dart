import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/app/router/main_shell_layout.dart';

void main() {
  group('Barra inferior', () {
    test('el miembro conserva las cinco pestañas de siempre', () {
      expect(
        memberTabs.map((tab) => tab.route).toList(),
        ['/home', '/events', '/publications', '/connect', '/profile'],
      );
    });

    test('el líder cambia Conectar por Mi Célula, y la barra no crece', () {
      // Seis pestañas recortarían las etiquetas de todas en un teléfono
      // pequeño, así que la de menos uso deja su sitio.
      expect(leaderTabs.length, memberTabs.length);

      final routes = leaderTabs.map((tab) => tab.route).toList();
      expect(routes, contains('/leader'));
      expect(routes, isNot(contains('/connect')));
    });

    test('Mi Célula va en segundo lugar, junto al inicio', () {
      expect(leaderTabs[1].route, '/leader');
      expect(leaderTabs[1].label, 'Mi Célula');
    });

    test('lo demás de la iglesia sigue en la barra del líder', () {
      final routes = leaderTabs.map((tab) => tab.route).toList();
      expect(routes, containsAll(['/home', '/events', '/publications', '/profile']));
    });
  });

  group('Pestaña activa', () {
    test('se marca la que corresponde a la dirección', () {
      expect(resolveTabIndex(leaderTabs, '/leader'), 1);
      expect(resolveTabIndex(leaderTabs, '/publications'), 3);
      expect(resolveTabIndex(memberTabs, '/connect'), 3);
      expect(resolveTabIndex(memberTabs, '/profile'), 4);
    });

    test('una subruta marca la pestaña de su sección', () {
      expect(resolveTabIndex(memberTabs, '/connect/prayer'), 3);
      expect(resolveTabIndex(leaderTabs, '/leader/meetings'), 1);
    });

    test('una dirección desconocida se queda en el inicio', () {
      expect(resolveTabIndex(memberTabs, '/lo-que-sea'), 0);
    });

    test('no se confunde una ruta que sólo empieza igual', () {
      // «/leaderboard» no es la sección del líder; sin comprobar la barra
      // separadora, `startsWith` la habría dado por buena.
      expect(resolveTabIndex(leaderTabs, '/leaderboard'), 0);
    });
  });
}
