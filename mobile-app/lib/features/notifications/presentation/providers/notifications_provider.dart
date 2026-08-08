import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/in_app_notification_banner.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/repositories/notifications_repository.dart';

class LocalNotification {
  final String id;
  final String title;
  final String body;
  final String receivedAt;
  final bool isRead;

  LocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });

  LocalNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? receivedAt,
    bool? isRead,
  }) {
    return LocalNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt,
        'isRead': isRead,
      };

  factory LocalNotification.fromJson(Map<String, dynamic> json) => LocalNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        receivedAt: json['receivedAt'],
        isRead: json['isRead'] ?? false,
      );
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRepositoryImpl(dio: apiClient.dio);
});

class LocalNotificationsNotifier extends StateNotifier<List<LocalNotification>> {
  static const _key = 'local_push_notifications';

  /// Antes se consultaba al servidor cada 5 segundos (y con dos peticiones por
  /// ciclo), lo que consumía batería y datos sin necesidad.
  static const _syncInterval = Duration(seconds: 30);

  Timer? _syncTimer;
  bool _isFirstSync = true;
  bool _isSyncing = false;
  String? _cachedUserId;
  String? _cachedUserIdForToken;
  dynamic _dio;

  LocalNotificationsNotifier() : super([]) {
    _loadFromPrefs();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Cantidad de notificaciones sin leer (usada por el badge del inicio).
  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Al iniciar o cerrar sesión el historial deja de ser válido: se limpia la
  /// caché de identidad y se vuelve a consultar de inmediato.
  void resetForSessionChange() {
    _cachedUserId = null;
    _cachedUserIdForToken = null;
    _isFirstSync = true;
    state = [];
    if (_dio != null) {
      fetchRemoteNotifications(_dio);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    state = jsonList.map((item) => LocalNotification.fromJson(json.decode(item))).toList();
  }

  Future<void> _saveToPrefs(List<LocalNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  void startAutoSync(dynamic dio) {
    _dio = dio;
    // Evita reiniciar el temporizador en cada reconstrucción de la pantalla.
    if (_syncTimer?.isActive ?? false) return;
    fetchRemoteNotifications(dio);
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      fetchRemoteNotifications(dio);
    });
  }

  Future<void> fetchRemoteNotifications(dynamic dio) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _dio = dio;
    try {
      // 1. Verificar si el usuario ha iniciado sesion leyendo el token seguro
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      // Si NO hay token (modo invitado / sin iniciar sesion), NO recibir ni mostrar notificaciones
      if (token == null || token.isEmpty) {
        _cachedUserId = null;
        _cachedUserIdForToken = null;
        if (state.isNotEmpty) {
          state = [];
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_key);
        }
        return;
      }

      // 2. Obtener el ID del usuario autenticado para la validación estricta.
      //    Se cachea por token: sólo se vuelve a pedir si la sesión cambió.
      //
      //    Se consulta /auth/me/, que es el perfil de la sesión. Antes se
      //    pedía /users/me/, que pertenece a la administración de cuentas y
      //    exige el permiso USERS_VIEW: devolvía 403 a cualquier miembro, así
      //    que el identificador quedaba nulo y este filtro nunca se aplicaba.
      if (_cachedUserId == null || _cachedUserIdForToken != token) {
        try {
          final meResponse = await dio.get('/auth/me/');
          if (meResponse.statusCode == 200 && meResponse.data != null) {
            _cachedUserId = meResponse.data['id']?.toString();
            _cachedUserIdForToken = token;
          }
        } catch (_) {}
      }
      final currentUserId = _cachedUserId;

      final prefs = await SharedPreferences.getInstance();
      final deletedIds = (prefs.getStringList('deleted_notification_ids') ?? []).toSet();

      final response = await dio.get('/notifications/');
      final results = response.data['results'] ?? response.data;
      if (results is List) {
        final existingIds = state.map((n) => n.id).toSet();
        // Conservar cuáles ya fueron leídas: antes cada sincronización las
        // volvía a marcar como no leídas y el badge nunca bajaba a cero.
        final readIds = state.where((n) => n.isRead).map((n) => n.id).toSet();
        final List<LocalNotification> fetched = [];
        bool hasNew = false;
        LocalNotification? newestNotification;

        for (final item in results) {
          final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          // Ignorar notificaciones eliminadas por el usuario
          if (deletedIds.contains(id)) continue;

          final targetUser = item['target_user']?.toString();

          // VALIDACIÓN ABSOLUTA EN CLIENTE (QA): Si la notificación tiene target_user asignado y NO es para el usuario actual -> DESCARTAR
          if (targetUser != null && targetUser.isNotEmpty && currentUserId != null) {
            if (targetUser != currentUserId) {
              continue;
            }
          }

          final title = item['title'] ?? 'Notificación Génesis';
          final body = item['body'] ?? '';
          final created = item['created_at'] ?? DateTime.now().toIso8601String();
          
          final notif = LocalNotification(
            id: id,
            title: title,
            body: body,
            receivedAt: created,
            isRead: readIds.contains(id),
          );

          if (!existingIds.contains(id)) {
            hasNew = true;
            newestNotification ??= notif;
          }
          fetched.add(notif);
        }

        state = fetched;
        await _saveToPrefs(fetched);

        // Solo lanzar alerta sonora y banner ruidoso si la notificación llega de verdad en tiempo real DESPUÉS del primer inicio
        if (hasNew && newestNotification != null && !_isFirstSync) {
          NotificationService().showSystemNotification(
            newestNotification.title,
            newestNotification.body,
          );

          // Se usa la clave del navegador realmente montado por la app; la
          // clave estática por defecto nunca se adjunta a un Navigator y el
          // banner jamás llegaba a mostrarse.
          final navState = NotificationService().activeNavigatorKey.currentState;
          final context = navState?.context;
          // El contexto se obtiene después de varias llamadas asíncronas: sólo
          // se usa si el navegador sigue montado.
          if (context != null && context.mounted) {
            InAppNotificationBanner.show(
              context,
              overlay: navState?.overlay,
              title: newestNotification.title,
              body: newestNotification.body,
            );
          }
        }
        _isFirstSync = false;
      }
    } catch (_) {
      // Sincronización silenciosa: no interrumpimos al usuario por un fallo
      // temporal de red; el siguiente ciclo lo reintenta.
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> markAsRead(String id) async {
    final updated = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> markAllAsRead() async {
    final updated = state.map((item) => item.copyWith(isRead: true)).toList();
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = (prefs.getStringList('deleted_notification_ids') ?? []).toSet();
    deletedIds.add(id);
    await prefs.setStringList('deleted_notification_ids', deletedIds.toList());

    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final currentIds = state.map((n) => n.id).toList();
    final deletedIds = (prefs.getStringList('deleted_notification_ids') ?? []).toSet();
    deletedIds.addAll(currentIds);
    await prefs.setStringList('deleted_notification_ids', deletedIds.toList());

    state = [];
    await prefs.remove(_key);
  }
}

final localNotificationsProvider = StateNotifierProvider<LocalNotificationsNotifier, List<LocalNotification>>((ref) {
  return LocalNotificationsNotifier();
});
