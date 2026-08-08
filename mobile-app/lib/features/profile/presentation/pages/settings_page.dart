import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../devotionals/presentation/providers/devotionals_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settingsAsync = ref.watch(publicSettingsProvider);
    final savedCount = ref.watch(savedDevotionalsProvider).length;
    final notificationsCount = ref.watch(localNotificationsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('CUENTA'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    authState.isAuthenticated ? Icons.verified_user_outlined : Icons.person_outline,
                    color: AppColors.dorado,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.isAuthenticated ? 'Sesión iniciada' : 'Modo invitado',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.user?.email ??
                              'Inicia sesión para guardar tus inscripciones y recibir avisos.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.crema.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (authState.isGuest)
                    TextButton(
                      onPressed: () => context.push('/auth/login'),
                      child: const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const _SectionTitle('NOTIFICACIONES'),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: 'Permisos de notificación',
            subtitle: authState.isGuest
                ? 'Los avisos personalizados requieren iniciar sesión'
                : 'Gestiona los avisos que llegan a tu celular',
            onTap: () async {
              final settings = await NotificationService().requestNotificationPermission();
              if (!context.mounted) return;
              final granted = settings.authorizationStatus.name == 'authorized';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted
                        ? 'Notificaciones activadas.'
                        : 'Las notificaciones están desactivadas. Puedes habilitarlas desde los ajustes del sistema.',
                  ),
                  backgroundColor: granted ? AppColors.success : AppColors.warning,
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.history,
            title: 'Historial de notificaciones',
            subtitle: '$notificationsCount en este dispositivo',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 24),

          const _SectionTitle('CONTENIDO GUARDADO'),
          _SettingsTile(
            icon: Icons.star_border,
            title: 'Devocionales guardados',
            subtitle: '$savedCount guardado${savedCount == 1 ? '' : 's'}',
            onTap: () => context.push('/profile/saved-devotionals'),
          ),
          _SettingsTile(
            icon: Icons.inbox_outlined,
            title: 'Mis solicitudes',
            subtitle: 'Peticiones de oración y visitas enviadas',
            onTap: () => context.push('/profile/my-requests'),
          ),
          _SettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Borrar datos guardados en el dispositivo',
            subtitle: 'Favoritos, historial de notificaciones y solicitudes',
            onTap: () => _confirmClearLocalData(context, ref),
          ),
          const SizedBox(height: 24),

          const _SectionTitle('LA IGLESIA'),
          settingsAsync.maybeWhen(
            data: (settings) {
              final phone = settings.church.whatsapp.isNotEmpty
                  ? settings.church.whatsapp
                  : settings.church.phone;
              return Column(
                children: [
                  if (settings.church.address.isNotEmpty)
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: 'Dirección',
                      subtitle: settings.church.address,
                      onTap: null,
                    ),
                  if (phone.isNotEmpty)
                    _SettingsTile(
                      icon: Icons.phone_outlined,
                      title: 'Teléfono',
                      subtitle: phone,
                      onTap: () => _launch('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}', context),
                    ),
                  if (settings.church.email.isNotEmpty)
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Correo',
                      subtitle: settings.church.email,
                      onTap: () => _launch('mailto:${settings.church.email}', context),
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Génesis App · Versión 1.1.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.crema.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _launch(String url, BuildContext context) async {
    try {
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (launched || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No pudimos abrir esta acción en tu dispositivo.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _confirmClearLocalData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Borrar datos locales', style: AppTextStyles.titleMedium),
        content: Text(
          'Se eliminarán tus devocionales guardados, el historial de notificaciones y el registro de solicitudes de este dispositivo. Tu cuenta no se verá afectada.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('BORRAR', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    // Se conserva `onboarding_completed` para no repetir la bienvenida.
    for (final key in [
      'saved_devotional_slugs',
      'local_push_notifications',
      'deleted_notification_ids',
      'submitted_requests_history',
    ]) {
      await prefs.remove(key);
    }

    ref.invalidate(savedDevotionalsProvider);
    ref.invalidate(localNotificationsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos locales borrados.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.doradoClaro,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.dorado, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.crema.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.dorado, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
