import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Timer? _syncTimer;

  LocalNotificationsNotifier() : super([]) {
    _loadFromPrefs();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
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
    _syncTimer?.cancel();
    fetchRemoteNotifications(dio);
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchRemoteNotifications(dio);
    });
  }

  Future<void> fetchRemoteNotifications(dynamic dio) async {
    try {
      final response = await dio.get('/notifications/');
      final results = response.data['results'] ?? response.data;
      if (results is List) {
        final existingIds = state.map((n) => n.id).toSet();
        final List<LocalNotification> fetched = [];
        bool hasNew = false;
        LocalNotification? newestNotification;

        for (final item in results) {
          final title = item['title'] ?? 'Notificación Génesis';
          final body = item['body'] ?? '';
          final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          final created = item['created_at'] ?? DateTime.now().toIso8601String();
          
          final notif = LocalNotification(
            id: id,
            title: title,
            body: body,
            receivedAt: created,
            isRead: false,
          );

          if (!existingIds.contains(id)) {
            hasNew = true;
            newestNotification ??= notif;
          }
          fetched.add(notif);
        }

        if (fetched.isNotEmpty) {
          state = fetched;
          await _saveToPrefs(fetched);

          // If a brand new notification arrived, show in-app banner immediately
          if (hasNew && newestNotification != null) {
            final navState = NotificationService.navigatorKey.currentState;
            final context = navState?.context;
            if (context != null) {
              InAppNotificationBanner.show(
                context,
                overlay: navState?.overlay,
                title: newestNotification.title,
                body: newestNotification.body,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> addNotification(String title, String body) async {
    final newNotif = LocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now().toIso8601String(),
    );
    final updated = [newNotif, ...state];
    state = updated;
    await _saveToPrefs(updated);
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

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final localNotificationsProvider = StateNotifierProvider<LocalNotificationsNotifier, List<LocalNotification>>((ref) {
  return LocalNotificationsNotifier();
});
