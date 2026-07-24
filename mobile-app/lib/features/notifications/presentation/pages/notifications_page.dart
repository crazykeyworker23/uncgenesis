import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(localNotificationsProvider);
    final apiClient = ref.watch(apiClientProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localNotificationsProvider.notifier).fetchRemoteNotifications(apiClient.dio);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.crema),
              tooltip: 'Marcar todas como leídas',
              onPressed: () {
                ref.read(localNotificationsProvider.notifier).markAllAsRead();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Borrar todo el historial',
              onPressed: () {
                _showClearConfirmation(context, ref);
              },
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.dorado),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones recibidas.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.crema.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final dateOnly = notif.receivedAt.split('T')[0];
                final timeOnly = notif.receivedAt.split('T')[1].substring(0, 5);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: notif.isRead ? AppColors.cardColor.withValues(alpha: 0.5) : AppColors.cardColor,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(localNotificationsProvider.notifier).markAsRead(notif.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: notif.isRead 
                                  ? AppColors.darkTeal.withValues(alpha: 0.5) 
                                  : AppColors.darkTeal,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: notif.isRead ? AppColors.crema.withValues(alpha: 0.5) : AppColors.dorado,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontSize: 15,
                                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.dorado,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.body,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: notif.isRead 
                                        ? AppColors.crema.withValues(alpha: 0.5) 
                                        : AppColors.crema.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$dateOnly a las $timeOnly HS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.crema.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('¿Borrar historial?', style: TextStyle(color: AppColors.dorado)),
          content: const Text(
            'Esta acción eliminará todas las notificaciones recibidas del dispositivo. No se puede deshacer.',
            style: TextStyle(color: AppColors.crema),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.crema)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                ref.read(localNotificationsProvider.notifier).clearAll();
                Navigator.pop(context);
              },
              child: const Text('BORRAR TODO', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }
}
