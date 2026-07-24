import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/notifications/notification_service.dart';
import '../providers/home_provider.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().showPermissionDialogIfNeeded(context);
      final apiClient = ref.read(apiClientProvider);
      ref.read(localNotificationsProvider.notifier).startAutoSync(apiClient.dio);
    });

    final settingsAsync = ref.watch(publicSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          // Background Image (Worship photo aligned to bottom so crowd fills lower screen)
          Positioned.fill(
            child: Image.asset(
              'assets/images/worship_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              width: double.infinity,
              height: double.infinity,
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
                            Image.asset(
                              'assets/logos/logo.png',
                              width: 44,
                              height: 44,
                              color: AppColors.dorado,
                            ),
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
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
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
                    const SizedBox(height: 32),

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
                            const Color(0xFF042F30).withOpacity(0.8),
                            const Color(0xFF021B1C).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.dorado.withOpacity(0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                                color: AppColors.dorado.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.dorado.withOpacity(0.6),
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
                            color: AppColors.dorado.withOpacity(0.3),
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
              const Color(0xFF042F30).withOpacity(0.85),
              const Color(0xFF021B1C).withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.dorado.withOpacity(0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
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
                  color: AppColors.dorado.withOpacity(0.4),
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
