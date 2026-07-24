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
                String dateOnly = notif.receivedAt;
                String timeOnly = '';

                if (notif.receivedAt.contains('T')) {
                  final parts = notif.receivedAt.split('T');
                  dateOnly = parts[0];
                  if (parts.length > 1 && parts[1].length >= 5) {
                    timeOnly = parts[1].substring(0, 5);
                  }
                } else if (notif.receivedAt.contains(' ')) {
                  final parts = notif.receivedAt.split(' ');
                  dateOnly = parts[0];
                  if (parts.length > 1 && parts[1].length >= 5) {
                    timeOnly = parts[1].substring(0, 5);
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: notif.isRead ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
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
                                  ? const Color(0xFF0D9488).withOpacity(0.4) 
                                  : const Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: notif.isRead ? Colors.white60 : const Color(0xFFD4AF37),
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
                                        style: TextStyle(
                                          color: Colors.white,
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
                                          color: Color(0xFFD4AF37),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.body,
                                  style: TextStyle(
                                    color: notif.isRead ? Colors.white70 : Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeOnly.isNotEmpty ? '$dateOnly - $timeOnly' : dateOnly,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
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
