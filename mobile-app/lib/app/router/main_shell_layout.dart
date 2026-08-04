import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShellLayout extends StatelessWidget {
  final Widget child;

  const MainShellLayout({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/events')) return 1;
    if (location.startsWith('/publications')) return 2;
    if (location.startsWith('/connect')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // default /home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/events');
        break;
      case 2:
        context.go('/publications');
        break;
      case 3:
        context.go('/connect');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      NavigationItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Inicio',
      ),
      NavigationItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Eventos',
      ),
      NavigationItemData(
        icon: Icons.article_outlined,
        activeIcon: Icons.article,
        label: 'Publicaciones',
      ),
      NavigationItemData(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Conectar',
      ),
      NavigationItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Perfil',
      ),
    ];

    final currentIndex = _getCurrentIndex(context);

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
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = currentIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(index, context),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.5),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.dorado : AppColors.crema.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bottom active line indicator
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
    );
  }
}

class NavigationItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
