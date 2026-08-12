import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/widgets/app_images.dart';
import '../providers/home_provider.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../leader/presentation/pages/leader_dashboard_page.dart';
import '../../../leader/presentation/providers/leader_providers.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Se ejecuta una sola vez: antes vivía dentro de `build`, así que cada
    // reconstrucción reiniciaba el temporizador de sincronización y volvía a
    // evaluar el diálogo de permisos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService().showPermissionDialogIfNeeded(context);
      final apiClient = ref.read(apiClientProvider);
      ref.read(localNotificationsProvider.notifier).startAutoSync(apiClient.dio);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Quien responde de una célula abre la aplicación con otra pregunta en la
    // cabeza —qué me falta hacer con mi gente— y tiene su propio inicio. El
    // arranque de notificaciones vive en `initState`, así que corre igual para
    // los dos.
    if (ref.watch(worksAsCellLeaderProvider)) {
      return const LeaderDashboardPage();
    }

    final settingsAsync = ref.watch(publicSettingsProvider);
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          // Background Image (Worship photo aligned to bottom so crowd fills lower screen)
          const Positioned.fill(
            child: AppBackground(
              'assets/images/worship_bg.png',
              alignment: Alignment.bottomCenter,
            ),
          ),
          // Subtle dark gradient overlay: darker at top for text readability, 100% transparent at bottom for photo vibrancy
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkGreen.withValues(alpha: 0.60),
                    AppColors.darkGreen.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(publicSettingsProvider);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Row: Logo + GÉNESIS — A P P — & Notification Bell
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 44, color: AppColors.dorado),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IG CHURCH',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    letterSpacing: 2.0,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  '— A P P —',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    letterSpacing: 4.0,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.doradoClaro,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none_outlined,
                                color: AppColors.dorado,
                                size: 28,
                              ),
                              // El contador refleja las notificaciones sin leer
                              // reales; antes estaba fijo en "3" incluso en
                              // modo invitado, donde no hay notificaciones.
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Estado de la sesión: deja claro si se navega como
                    // invitado y ofrece el acceso directo a iniciar sesión.
                    _SessionBanner(authState: authState),
                    const SizedBox(height: 12),

                    // Cursive Hero Welcome Texts: Bienvenido a Génesis
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Bienvenido a',
                            style: TextStyle(
                              fontFamily: 'cursive',
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              color: AppColors.doradoClaro,
                            ),
                          ),
                          SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Génesis un nuevo Comenzar',
                                  style: TextStyle(
                                    fontFamily: 'cursive',
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: CustomPaint(
                                    size: Size(18, 14),
                                    painter: SplashAccentPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          // Subtitle: Una casa para todos
                          Text(
                            'Una casa para todos ♡',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              color: AppColors.doradoClaro,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Grid of 6 quick access buttons (3x2)
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        _buildGridItem(
                          context,
                          icon: Icons.newspaper_outlined,
                          label: 'Noticias',
                          onTap: () => context.go('/publications'),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.church_outlined,
                          label: 'Servicios',
                          onTap: () => context.push('/services'),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.people_outline,
                          label: 'Células',
                          onTap: () => context.push('/cells'),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.menu_book_outlined,
                          label: 'Devocionales',
                          onTap: () => context.push('/devotionals'),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.volunteer_activism_outlined,
                          label: 'Oración',
                          onTap: () => context.push('/connect/prayer'),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.chat_bubble_outline,
                          label: 'Contacto',
                          onTap: () => context.push('/connect/visitor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  ),

                  // Next Service Card anchored at bottom of screen
                  Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF042F30).withValues(alpha: 0.8),
                            const Color(0xFF021B1C).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.dorado.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Concentric Circular Calendar Icon Container
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.dorado.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.dorado.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.dorado,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Vertical divider line
                          Container(
                            height: 48,
                            width: 1,
                            color: AppColors.dorado.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próximo servicio',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.doradoClaro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  settingsAsync.maybeWhen(
                                    data: (settings) =>
                                        settings.schedules.isNotEmpty
                                        ? settings.schedules
                                              .map(
                                                (s) =>
                                                    '${s.dayOfWeekDisplay} ${s.startTime}',
                                              )
                                              .join(' y ')
                                        : 'Domingo 10:00 AM y 6:00 PM',
                                    orElse: () => 'Domingo 10:00 AM y 6:00 PM',
                                  ),
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: 18,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF042F30).withValues(alpha: 0.85),
              const Color(0xFF021B1C).withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.dorado.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.dorado.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Icon(icon, color: AppColors.doradoClaro, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 14,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.dorado,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Franja superior que identifica el modo de uso actual.
///
/// En modo invitado invita a iniciar sesión (sin bloquear el contenido) y con
/// sesión iniciada saluda a la persona por su nombre.
class _SessionBanner extends StatelessWidget {
  final AuthState authState;

  const _SessionBanner({required this.authState});

  @override
  Widget build(BuildContext context) {
    if (authState.isLoading) return const SizedBox.shrink();

    final user = authState.user;
    final isAuthenticated = user != null;
    final firstName = isAuthenticated
        ? (user.firstName?.trim().isNotEmpty == true
            ? user.firstName!.trim()
            : user.fullName.split(' ').first)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF042F30).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dorado.withValues(alpha: isAuthenticated ? 0.30 : 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAuthenticated ? Icons.verified_user_outlined : Icons.person_outline,
            color: AppColors.doradoClaro,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAuthenticated
                  ? 'Hola, $firstName · Sesión iniciada'
                  : 'Estás navegando como invitado',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isAuthenticated)
            TextButton(
              onPressed: () => context.push('/auth/login'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.dorado,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'INICIAR SESIÓN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class SplashAccentPainter extends CustomPainter {
  const SplashAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFE76F51) // warm orange/gold brush color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw three diagonal lines next to each other
    canvas.drawLine(const Offset(2, 10), const Offset(6, 2), paint);
    canvas.drawLine(const Offset(7, 12), const Offset(11, 4), paint);
    canvas.drawLine(const Offset(12, 14), const Offset(16, 6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
