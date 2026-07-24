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
      backgroundColor: const Color(0xFF0B132B), // Deep Obsidian Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mis Notificaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Color(0xFFF59E0B)),
              tooltip: 'Marcar todas como leídas',
              onPressed: () {
                ref.read(localNotificationsProvider.notifier).markAllAsRead();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.notifications_off_outlined, size: 56, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sin notificaciones personales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Las notificaciones que recibas aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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

                final isRead = notif.isRead;

                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(localNotificationsProvider.notifier).deleteNotification(notif.id);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRead
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFF0F172A), const Color(0xFF064E3B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isRead
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFD4AF37).withOpacity(0.5),
                        width: isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        if (!isRead)
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          ref.read(localNotificationsProvider.notifier).markAsRead(notif.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row: Tag + Date + Delete Button
                              Row(
                                children: [
                                  // Gold Icon Badge
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: isRead
                                          ? const LinearGradient(
                                              colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                            )
                                          : const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isRead ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                                      color: isRead ? Colors.white54 : const Color(0xFF0F172A),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Header Tag
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'GÉNESIS NOTIFICACIONES',
                                            style: TextStyle(
                                              color: isRead ? Colors.white38 : const Color(0xFFF59E0B),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                                              ),
                                              child: const Text(
                                                'NUEVO',
                                                style: TextStyle(
                                                  color: Color(0xFFF59E0B),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeOnly.isNotEmpty ? '$dateOnly • $timeOnly' : dateOnly,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Close / Delete Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    tooltip: 'Eliminar notificación',
                                    onPressed: () {
                                      ref.read(localNotificationsProvider.notifier).deleteNotification(notif.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Notification Title
                              Text(
                                notif.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Notification Body
                              Text(
                                notif.body,
                                style: TextStyle(
                                  color: isRead ? Colors.white.withOpacity(0.65) : Colors.white.withOpacity(0.88),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Borrar todo el historial?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción eliminará todas las notificaciones personales de tu teléfono.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(localNotificationsProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
