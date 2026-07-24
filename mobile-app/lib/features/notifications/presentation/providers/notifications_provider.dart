import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/core_providers.dart';
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

  LocalNotificationsNotifier() : super([]) {
    _loadFromPrefs();
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

  Future<void> fetchRemoteNotifications(dynamic dio) async {
    try {
      final response = await dio.get('/notifications/');
      final results = response.data['results'] ?? response.data;
      if (results is List) {
        final List<LocalNotification> fetched = [];
        for (final item in results) {
          final title = item['title'] ?? 'Notificación Génesis';
          final body = item['body'] ?? '';
          final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          final created = item['created_at'] ?? DateTime.now().toIso8601String();
          fetched.add(LocalNotification(
            id: id,
            title: title,
            body: body,
            receivedAt: created,
            isRead: false,
          ));
        }
        if (fetched.isNotEmpty) {
          state = fetched;
          await _saveToPrefs(fetched);
        }
      }
    } catch (_) {}
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
