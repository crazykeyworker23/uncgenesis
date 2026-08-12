import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: authState.maybeWhen(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.dorado),
        ),
        authenticated: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Avatar, Name, Email)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.dorado,
                      backgroundImage: user.avatar != null 
                          ? NetworkImage(user.avatar!) 
                          : null,
                      child: user.avatar == null
                          ? Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 22, color: AppColors.dorado),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Personal Info Section
              if (user.phone != null && user.phone!.isNotEmpty ||
                  user.location != null && user.location!.isNotEmpty ||
                  user.bio != null && user.bio!.isNotEmpty) ...[
                Card(
                  color: AppColors.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMACIÓN PERSONAL',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.doradoClaro,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          _ProfileInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Teléfono',
                            value: user.phone!,
                          ),
                        if (user.location != null && user.location!.isNotEmpty) ...[
                          if (user.phone != null && user.phone!.isNotEmpty) const Divider(color: AppColors.darkTeal),
                          _ProfileInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Ubicación',
                            value: user.location!,
                          ),
                        ],
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          if (user.phone != null && user.phone!.isNotEmpty ||
                              user.location != null && user.location!.isNotEmpty)
                            const Divider(color: AppColors.darkTeal),
                          _ProfileInfoRow(
                            icon: Icons.info_outline,
                            label: 'Biografía',
                            value: user.bio!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Gestión de célula para el pastorado.
              //
              // El líder y el coordinador no la ven aquí: tienen su propia
              // pestaña en la barra inferior y repetirla sería ruido. Queda
              // para quien alcanza las células por su cargo en la iglesia y no
              // responde de ninguna en concreto, que sí necesita una puerta.
              if (user.leadsAnyCell && !user.scope.hasOwnCells) ...[
                _LeaderMenuCard(onTap: () => context.push('/leader')),
                const SizedBox(height: 20),
              ],

              // 4. Actions / Menu Options
              _ProfileMenuCard(
                title: 'Editar Perfil',
                icon: Icons.edit_outlined,
                onTap: () => context.push('/profile/edit'),
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                title: 'Devocionales Guardados',
                icon: Icons.star_border,
                onTap: () => context.push('/profile/saved-devotionals'),
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                title: 'Mis Eventos Registrados',
                icon: Icons.event_available_outlined,
                onTap: () => context.push('/profile/my-events'),
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                title: 'Mis Solicitudes',
                icon: Icons.inbox_outlined,
                onTap: () => context.push('/profile/my-requests'),
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                title: 'Notificaciones',
                icon: Icons.notifications_none_outlined,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                title: 'Configuración',
                icon: Icons.settings_outlined,
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 32),

              // 5. Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                // Se confirma antes de cerrar: antes bastaba un toque
                // accidental para perder la sesión.
                onPressed: () => _confirmLogout(context, ref),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        orElse: () => const _UnauthenticatedView(),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión', style: AppTextStyles.titleMedium),
        content: Text(
          '¿Deseas cerrar tu sesión? Podrás seguir usando la app como invitado.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CERRAR SESIÓN', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada. Continúas como invitado.'),
        backgroundColor: AppColors.darkTeal,
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.dorado, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.crema.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Acceso a la gestión de células para el pastorado.
///
/// Quien lidera o coordina un grupo llega por su pestaña; esta tarjeta es la
/// puerta de quien alcanza las células por su cargo en la iglesia.
class _LeaderMenuCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaderMenuCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dorado.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dorado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.dorado, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Células de la iglesia',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.doradoClaro,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Miembros, reuniones, seguimientos, informes y avisos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.dorado, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.dorado, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.dorado, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista del perfil en modo invitado.
///
/// Antes sólo mostraba el botón de iniciar sesión: todo lo que sí funciona sin
/// cuenta (devocionales guardados, solicitudes enviadas, configuración) quedaba
/// inaccesible desde aquí.
class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.account_circle_outlined, size: 72, color: AppColors.dorado),
          const SizedBox(height: 16),
          Text(
            'Estás como invitado',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.doradoClaro),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Al iniciar sesión podrás editar tu información personal, inscribirte a eventos y recibir avisos de la iglesia.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: () => context.push('/auth/login'),
            child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dorado,
              side: const BorderSide(color: AppColors.dorado),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.push('/auth/register'),
            child: const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),

          Text(
            'DISPONIBLE SIN CUENTA',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.doradoClaro,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _ProfileMenuCard(
            title: 'Devocionales Guardados',
            icon: Icons.star_border,
            onTap: () => context.push('/profile/saved-devotionals'),
          ),
          const SizedBox(height: 12),
          _ProfileMenuCard(
            title: 'Mis Solicitudes',
            icon: Icons.inbox_outlined,
            onTap: () => context.push('/profile/my-requests'),
          ),
          const SizedBox(height: 12),
          _ProfileMenuCard(
            title: 'Configuración',
            icon: Icons.settings_outlined,
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
