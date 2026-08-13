import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
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

  /// Clave del navegador realmente montado por la app (la asigna `initialize`).
  /// Sirve para mostrar banners internos desde código sin `BuildContext`.
  GlobalKey<NavigatorState> get activeNavigatorKey => _navigatorKey ?? navigatorKey;

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: defaultFirebaseOptions);
      } catch (e) {
        debugPrint("Firebase initializeApp note: $e");
      }
    }
  }

  /// Canal por el que Android muestra los avisos con la app cerrada.
  ///
  /// El mismo identificador viaja en cada mensaje desde el servidor
  /// (`channel_id` en `apps/notifications/push.py`) y está declarado en el
  /// AndroidManifest como canal por defecto: los tres deben coincidir.
  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'genesis_channel',
    'Notificaciones Génesis',
    description: 'Avisos de la iglesia: devocionales, eventos y recordatorios.',
    // Importancia máxima: es lo que hace que el aviso salte sobre la pantalla
    // en lugar de quedarse callado en la barra de estado.
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotificationsPlugin.initialize(
        initSettings,
        // Los avisos que levanta la propia app no llevaban a ninguna parte:
        // sólo la abrían. El destino viaja en el `payload`.
        onDidReceiveNotificationResponse: (response) => openDeepLink(response.payload),
      );

      // Sin este registro el canal no existe, y con la app cerrada Android
      // descartaba el aviso o lo mostraba en un canal silencioso de reserva:
      // la notificación se enviaba pero el teléfono no avisaba de nada.
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_canal);
    } catch (e) {
      debugPrint("initLocalNotifications error: $e");
    }
  }

  Future<void> showSystemNotification(String title, String body, {String? deepLink}) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'genesis_channel',
        'Notificaciones Génesis',
        channelDescription: 'Canal de notificaciones de Génesis App',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification',
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: deepLink,
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

  /// Registra el dispositivo en el backend para poder recibir avisos.
  ///
  /// `POST /notifications/devices/` es público a propósito: el modelo FCMDevice
  /// admite `user` nulo para que un invitado también quede registrado. Si hay
  /// sesión iniciada, el interceptor añade el token y el dispositivo queda
  /// asociado a esa cuenta.
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
    openDeepLink(message.data['deep_link'] as String?);
  }

  /// Rutas que un aviso puede abrir. Se comprueba contra esta lista para que un
  /// mensaje con una ruta inesperada no deje la app en una pantalla de error.
  static const _destinosPermitidos = [
    '/devotionals',
    '/events',
    '/publications',
    '/services',
    '/cells',
    '/notifications',
  ];

  /// Abre la pantalla que corresponde a un aviso.
  ///
  /// La usan los tres caminos por los que se puede tocar uno: el que llega por
  /// Firebase, el que levanta la propia app y el listado de dentro. Así los
  /// tres llevan al mismo sitio.
  Future<void> openDeepLink(String? ruta, {GoRouter? router}) async {
    final navegador = router ?? appRouter;

    final destino = (ruta != null && ruta.isNotEmpty &&
            _destinosPermitidos.any((permitido) => ruta.startsWith(permitido)))
        ? ruta
        // Un aviso suelto (un comunicado, por ejemplo) no apunta a ninguna
        // pantalla concreta: se abre el listado de notificaciones.
        : '/notifications';

    // Si la app venía cerrada, el splash todavía está decidiendo a dónde ir.
    // Navegar antes de que termine haría que nos pisara la ruta y el usuario
    // acabaría en el inicio en lugar de en lo que tocó.
    // `state.uri` y no `currentConfiguration.uri`: el segundo informa de la
    // pantalla base y se queda corto en cuanto hay algo apilado encima, que es
    // justo lo que hacen estos avisos.
    for (var intento = 0; intento < 30; intento++) {
      final actual = navegador.state.uri.path;
      if (actual != '/splash' && actual != '/') break;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      final actual = navegador.state.uri.path;

      // Todavía no ha entrado a la app: primero termina de presentarse o de
      // iniciar sesión, y no se le saca de ahí a media faena.
      if (actual == '/onboarding' || actual.startsWith('/auth')) return;

      // Ya está mirando eso: apilar otra copia encima no aporta y le obliga a
      // volver dos veces.
      if (actual == destino) return;

      // Se apila encima, no se reemplaza. Con `go` la pantalla del aviso
      // quedaba sola en la pila: no salía la flecha de volver y el botón de
      // atrás del teléfono cerraba la aplicación.
      navegador.push(destino);
    } catch (e) {
      debugPrint('No se pudo abrir el destino del aviso ($destino): $e');
    }
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

  static const _permissionDismissedKey = 'notification_permission_dismissed';

  Future<void> showPermissionDialogIfNeeded(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Si el usuario ya respondió "Ahora no", no se le vuelve a preguntar.
      if (prefs.getBool(_permissionDismissedKey) ?? false) return;

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
              side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
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
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_permissionDismissedKey, true);
                },
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
