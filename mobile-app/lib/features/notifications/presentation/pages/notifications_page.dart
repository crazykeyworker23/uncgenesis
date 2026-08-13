import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // La sincronización se pedía dentro de `build`: cada respuesta cambiaba el
    // estado, provocaba otra reconstrucción y otra petición, dejando la
    // pantalla consultando al servidor sin parar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(localNotificationsProvider.notifier).fetchRemoteNotifications(
            ref.read(apiClientProvider).dio,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(localNotificationsProvider);
    final isGuest = ref.watch(authProvider).isGuest;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Deep Dark Obsidian Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Centro de Notificaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
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
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.notifications_off_outlined, size: 52, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isGuest ? 'Notificaciones no disponibles' : 'Sin notificaciones personales',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      // En modo invitado no hay cuenta a la que enviar avisos:
                      // se explica en vez de dejar una pantalla vacía sin motivo.
                      isGuest
                          ? 'Inicia sesión para recibir los avisos y comunicados que la iglesia envía a tu cuenta.'
                          : 'Las notificaciones enviadas a tu cuenta aparecerán aquí en tiempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () => context.push('/auth/login'),
                      child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                // Fecha y hora en formato local y legible; antes se mostraba
                // el texto ISO en UTC tal cual venía del servidor.
                final dateOnly = DateFormatter.relative(notif.receivedAt, fallback: '');
                final timeOnly = DateFormatter.time(notif.receivedAt) ?? '';

                final isRead = notif.isRead;

                // Lo que uno mismo mandó no es un aviso entrante: aparece como
                // constancia de lo enviado y se distingue a simple vista, para
                // que el líder no lo confunda con un mensaje de otra persona.
                final sentByMe = notif.sentByMe;
                const sentTone = Color(0xFF34D399);

                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(localNotificationsProvider.notifier).deleteNotification(notif.id);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRead
                            ? [const Color(0xFF131C2E), const Color(0xFF0F172A)]
                            : [const Color(0xFF0F172A), const Color(0xFF042F2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRead
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.55),
                        width: isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        if (!isRead)
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          ref.read(localNotificationsProvider.notifier).markAsRead(notif.id);
                          // Y se abre lo que el aviso anuncia. Antes sólo se
                          // marcaba como leído: había que buscar a mano el
                          // devocional o la célula de la que hablaba.
                          NotificationService().openDeepLink(notif.deepLink);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar: Badge Icon + Tag + Date + NUEVO Indicator + Close Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Glowing Circular Icon Badge
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: isRead
                                          ? const LinearGradient(
                                              colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                            )
                                          : const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        if (!isRead)
                                          BoxShadow(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Icon(
                                      sentByMe
                                          ? Icons.send_rounded
                                          : isRead
                                              ? Icons.mark_email_read_outlined
                                              : Icons.notifications_active_rounded,
                                      color: isRead && !sentByMe
                                          ? Colors.white54
                                          : const Color(0xFF0F172A),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Header Tag & Date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: sentByMe
                                                    ? sentTone
                                                    : isRead
                                                        ? Colors.white38
                                                        : const Color(0xFFF59E0B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              sentByMe ? 'ENVIADO POR TI' : 'GÉNESIS APP',
                                              style: TextStyle(
                                                color: sentByMe
                                                    ? sentTone
                                                    : isRead
                                                        ? Colors.white38
                                                        : const Color(0xFFF59E0B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            // «NUEVO» sólo tiene sentido en lo
                                            // que llega de fuera: lo propio ya
                                            // se sabe.
                                            if (!isRead && !sentByMe) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
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
                                            color: Colors.white.withValues(alpha: 0.45),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Close / Delete Button
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(localNotificationsProvider.notifier).deleteNotification(notif.id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Notification Title
                              Text(
                                notif.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Notification Message Body
                              Text(
                                notif.body,
                                style: TextStyle(
                                  color: isRead ? Colors.white.withValues(alpha: 0.65) : const Color(0xFFE2E8F0),
                                  fontSize: 13.5,
                                  height: 1.45,
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
