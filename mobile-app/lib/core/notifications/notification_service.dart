import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';
import '../widgets/in_app_notification_banner.dart';

@pragma('vm:entry-point')
const defaultFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBfckSDgGFLMx06d7Rq7fBMqHHFlF7Di4Q',
  appId: '1:795991911200:android:ca7bfc410444028f474545',
  messagingSenderId: '795991911200',
  projectId: 'uncgenesis',
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      await Firebase.initializeApp(options: defaultFirebaseOptions);
    }
  }
  debugPrint("FCM Handling background message: ${message.messageId}");
  final title = message.notification?.title ?? message.data['title'] ?? 'Notificación Génesis';
  final body = message.notification?.body ?? message.data['body'] ?? 'Tienes un nuevo mensaje.';
  await NotificationService.saveToHistory(title, body);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  ApiClient? _apiClient;
  GlobalKey<NavigatorState>? _navigatorKey;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: defaultFirebaseOptions);
      } catch (e) {
        debugPrint("Firebase initializeApp note: $e");
      }
    }
  }

  Future<void> initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotificationsPlugin.initialize(initSettings);
    } catch (e) {
      debugPrint("initLocalNotifications error: $e");
    }
  }

  Future<void> showSystemNotification(String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'genesis_channel',
        'Notificaciones Génesis',
        channelDescription: 'Canal de notificaciones de Génesis App',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Local notification show error: $e');
    }
  }

  Future<void> initialize({
    required ApiClient apiClient,
    GlobalKey<NavigatorState>? navKey,
  }) async {
    _apiClient = apiClient;
    if (navKey != null) {
      _navigatorKey = navKey;
    } else {
      _navigatorKey = navigatorKey;
    }

    await initLocalNotifications();

    try {
      // 1. Ensure Firebase Core is initialized safely
      await _ensureFirebaseInitialized();

      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM User permission status: ${settings.authorizationStatus}');

      // 4. Foreground presentation options for iOS
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Get and Register FCM Token
      try {
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token obtained: $token');
          await registerToken(token);
        } else {
          await registerToken();
        }
      } catch (tokenErr) {
        debugPrint('FCM getToken error (google-services.json may be missing): $tokenErr');
        await registerToken();
      }

      // 6. Listen for Token Refresh
      messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        await registerToken(newToken);
      });

      // 7. Handle Foreground Notifications (When using the mobile app)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 8. Handle Notification Click (App opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped to open app: ${message.notification?.title}');
        _handleNotificationTap(message);
      });

      // 9. Check if app was opened from terminated state by notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App opened from terminated state by notification: ${initialMessage.notification?.title}');
        _handleNotificationTap(initialMessage);
      }

    } catch (e, stack) {
      debugPrint('Error initializing FCM NotificationService: $e\n$stack');
      // Attempt fallback registration so device is registered with backend
      await registerToken();
    }
  }

  Future<void> registerToken([String? explicitToken]) async {
    if (_apiClient == null) return;
    String? token = explicitToken;
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Could not fetch FCM token from Firebase SDK: $e');
        token = 'dev_token_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    if (token == null || token.isEmpty) return;

    try {
      final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
      final response = await _apiClient!.dio.post(
        '/notifications/devices/',
        data: {
          'token': token,
          'device_type': deviceType,
        },
      );
      debugPrint('FCM Device token registered successfully with backend: ${response.statusCode}');
    } catch (e) {
      debugPrint('Failed to register FCM Device token with backend: $e');
    }
  }

  static Future<void> saveToHistory(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'local_push_notifications';
      final jsonList = prefs.getStringList(key) ?? [];

      if (jsonList.isNotEmpty) {
        try {
          final firstItem = json.decode(jsonList.first) as Map<String, dynamic>;
          if (firstItem['title'] == title && firstItem['body'] == body) {
            final receivedAt = DateTime.tryParse(firstItem['receivedAt'] ?? '');
            if (receivedAt != null && DateTime.now().difference(receivedAt).inSeconds < 5) {
              return;
            }
          }
        } catch (_) {}
      }

      final newItem = json.encode({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'receivedAt': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      jsonList.insert(0, newItem);
      await prefs.setStringList(key, jsonList);
      debugPrint('Notification persisted to local history: $title');
    } catch (e) {
      debugPrint('Error saving notification to history: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notificación Génesis';
    final body = message.notification?.body ?? message.data['body'] ?? 'Tienes un nuevo mensaje.';

    saveToHistory(title, body);

    final navState = _navigatorKey?.currentState;
    final overlayState = navState?.overlay;
    final context = navState?.context ?? _navigatorKey?.currentContext;

    if (context != null) {
      InAppNotificationBanner.show(
        context,
        overlay: overlayState,
        title: title,
        body: body,
        onTap: () {
          _handleNotificationTap(message);
        },
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notificación Génesis';
    final body = message.notification?.body ?? message.data['body'] ?? 'Tienes un nuevo mensaje.';
    saveToHistory(title, body);
    debugPrint("Tapped notification payload: ${message.data}");
  }

  Future<NotificationSettings> requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Notification permission status: ${settings.authorizationStatus}');
    return settings;
  }

  Future<void> showPermissionDialogIfNeeded(BuildContext context) async {
    try {
      await _ensureFirebaseInitialized();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Activar Notificaciones',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Para recibir mensajes de la comunidad, avisos de servicios y comunicados en tiempo real directamente en tu celular, por favor permite las notificaciones.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Ahora no', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final newSettings = await requestNotificationPermission();
                  if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
                    final token = await messaging.getToken();
                    if (token != null) await registerToken(token);
                  }
                },
                child: const Text('Permitir Notificaciones', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking notification settings for dialog: $e');
    }
  }
}
