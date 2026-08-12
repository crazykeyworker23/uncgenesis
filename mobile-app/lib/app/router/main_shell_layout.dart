import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/leader/presentation/providers/leader_providers.dart';
import '../theme/app_colors.dart';

/// Una pestaña de la barra inferior.
class NavigationItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Navegación de quien viene a la iglesia.
const List<NavigationItemData> memberTabs = [
  NavigationItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Inicio',
    route: '/home',
  ),
  NavigationItemData(
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    label: 'Eventos',
    route: '/events',
  ),
  NavigationItemData(
    icon: Icons.article_outlined,
    activeIcon: Icons.article,
    label: 'Publicaciones',
    route: '/publications',
  ),
  NavigationItemData(
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: 'Conectar',
    route: '/connect',
  ),
  NavigationItemData(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Perfil',
    route: '/profile',
  ),
];

/// Navegación de quien responde de una célula.
///
/// «Mi Célula» ocupa el sitio de «Conectar», que es lo que menos usa: sirve
/// para que alguien nuevo pida oración o contacto, no para el trabajo semanal
/// del líder. Siguen a un toque desde su inicio, en el bloque «De la iglesia».
///
/// Cinco pestañas es el límite cómodo en un teléfono; una sexta recortaría las
/// etiquetas de todas.
const List<NavigationItemData> leaderTabs = [
  NavigationItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Inicio',
    route: '/home',
  ),
  NavigationItemData(
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    label: 'Mi Célula',
    route: '/leader',
  ),
  NavigationItemData(
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    label: 'Eventos',
    route: '/events',
  ),
  NavigationItemData(
    icon: Icons.article_outlined,
    activeIcon: Icons.article,
    label: 'Publicaciones',
    route: '/publications',
  ),
  NavigationItemData(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Perfil',
    route: '/profile',
  ),
];

/// Devuelve la pestaña activa a partir de la dirección actual.
///
/// Se resuelve contra la propia lista de pestañas en lugar de una cadena de
/// condiciones: así la barra y el destino de cada toque no pueden discrepar.
/// Gana la coincidencia más larga, para que `/leader` no se lleve por delante
/// una futura ruta que empiece igual.
int resolveTabIndex(List<NavigationItemData> tabs, String location) {
  var best = 0;
  var bestLength = 0;

  for (var i = 0; i < tabs.length; i++) {
    final route = tabs[i].route;
    final matches = location == route || location.startsWith('$route/');
    if (matches && route.length > bestLength) {
      best = i;
      bestLength = route.length;
    }
  }

  return best;
}

class MainShellLayout extends ConsumerWidget {
  final Widget child;

  const MainShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(worksAsCellLeaderProvider) ? leaderTabs : memberTabs;
    final currentIndex = resolveTabIndex(tabs, GoRouterState.of(context).uri.path);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF04241C).withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(
              color: AppColors.dorado.withValues(alpha: 0.20),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (index) {
                  final item = tabs[index];
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? AppColors.dorado
                                : AppColors.crema.withValues(alpha: 0.5),
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.dorado
                                  : AppColors.crema.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subrayado de la pestaña activa.
                          Container(
                            width: 20,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.dorado : Colors.transparent,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
