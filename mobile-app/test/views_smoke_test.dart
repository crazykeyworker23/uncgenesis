import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import 'package:genesis_app/features/auth/presentation/pages/login_page.dart';
import 'package:genesis_app/features/auth/presentation/pages/register_page.dart';
import 'package:genesis_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:genesis_app/features/home/presentation/pages/home_page.dart';
import 'package:genesis_app/features/publications/presentation/pages/publications_page.dart';
import 'package:genesis_app/features/services/presentation/pages/services_page.dart';
import 'package:genesis_app/features/devotionals/presentation/pages/devotionals_page.dart';
import 'package:genesis_app/features/events/presentation/pages/events_page.dart';
import 'package:genesis_app/features/cells/presentation/pages/cells_page.dart';
import 'package:genesis_app/features/requests/presentation/pages/connect_page.dart';
import 'package:genesis_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:genesis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:genesis_app/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:genesis_app/features/profile/presentation/pages/settings_page.dart';

import 'package:genesis_app/core/providers/core_providers.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {
    'access_token': 'fake_access',
    'refresh_token': 'fake_refresh',
  };

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data[key] = value ?? '';
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

class MockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    String responseString = '[]';
    int statusCode = 200;

    if (path.contains('/settings/public/')) {
      responseString = '{"app":{"app_name":"Génesis","app_description":"","splash_text":"","primary_color":"#000000","secondary_color":"#ffffff"},"church":{"church_name":"Iglesia","address":"","city":"","country":"","email":"","website":"","whatsapp":""},"schedules":[],"social_networks":[]}';
    } else if (path.contains('/devotionals/today/')) {
      responseString = '{"id":1,"title":"Devocional","slug":"dev","content":"Content","verse_reference":"","verse_text":"","date":"2026-07-10"}';
    } else if (path.contains('/auth/me/')) {
      responseString = '{"id":1,"email":"t@t.com","first_name":"Test","last_name":"User","full_name":"Test User","phone":"","status":"ACTIVE"}';
    } else if (path.contains('/auth/login/')) {
      responseString = '{"access":"access_token","refresh":"refresh_token"}';
    } else if (path.contains('/cells/')) {
      responseString = '{"results":[],"count":0}';
    } else if (path.contains('/publications/')) {
      responseString = '{"results":[],"count":0}';
    } else if (path.contains('/events/')) {
      responseString = '{"results":[],"count":0}';
    } else if (path.contains('/services/')) {
      responseString = '{"results":[],"count":0}';
    } else if (path.contains('/devotionals/')) {
      responseString = '{"results":[],"count":0}';
    } else if (path.contains('/publications/categories/')) {
      responseString = '[]';
    }

    final data = utf8.encode(responseString);
    return ResponseBody.fromBytes(
      data,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Widget createTestWidget(Widget child, {bool authenticated = true}) {
    final dio = Dio();
    dio.options.baseUrl = 'http://localhost:8000/api/v1';
    dio.httpClientAdapter = MockAdapter();

    final storage = FakeSecureStorage();
    if (!authenticated) {
      storage.data.clear();
    }

    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        secureStorageProvider.overrideWith((ref) => storage),
        dioProvider.overrideWith((ref) => dio),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Views Smoke Tests', () {
    testWidgets('LoginPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage(), authenticated: false));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('RegisterPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterPage(), authenticated: false));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('ForgotPasswordPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const ForgotPasswordPage(), authenticated: false));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('HomePage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomePage()));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('PublicationsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const PublicationsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(PublicationsPage), findsOneWidget);
    });

    testWidgets('ServicesPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const ServicesPage()));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesPage), findsOneWidget);
    });

    testWidgets('DevotionalsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const DevotionalsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(DevotionalsPage), findsOneWidget);
    });

    testWidgets('EventsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const EventsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(EventsPage), findsOneWidget);
    });

    testWidgets('CellsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(CellsPage), findsOneWidget);
    });

    testWidgets('ConnectPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const ConnectPage()));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectPage), findsOneWidget);
    });

    testWidgets('NotificationsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const NotificationsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('ProfilePage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfilePage()));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('ProfileEditPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileEditPage()));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditPage), findsOneWidget);
    });

    testWidgets('SettingsPage loads successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
