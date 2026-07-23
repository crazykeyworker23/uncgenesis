import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
  );

  runApp(
    const ProviderScope(
      child: GenesisApp(),
    ),
  );

  // Non-blocking background initialization so the app renders immediately (0ms)
  Future.microtask(() async {
    try {
      await ApiClient.determineBaseUrl();
      await NotificationService().initialize(
        apiClient: apiClient,
        navKey: rootNavigatorKey,
      );
    } catch (_) {}
  });
}
