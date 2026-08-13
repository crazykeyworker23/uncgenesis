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
import 'package:genesis_app/features/leader/presentation/pages/leader_home_page.dart';
import 'package:genesis_app/features/leader/presentation/pages/cell_members_page.dart';
import 'package:genesis_app/features/leader/presentation/pages/cell_meetings_page.dart';
import 'package:genesis_app/features/leader/presentation/pages/cell_follow_ups_page.dart';
import 'package:genesis_app/features/leader/presentation/pages/cell_reports_page.dart';
import 'package:genesis_app/features/leader/presentation/pages/cell_announcement_page.dart';

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
  /// Con `false`, `/auth/me/` responde como un miembro corriente: sirve para
  /// comprobar que la gestión de célula no se le ofrece.
  final bool asLeader;

  MockAdapter({this.asLeader = false});

  static const _leaderScope =
      '"roles":["CELL_LEADER"],"permissions":["MEETINGS_VIEW","MEETINGS_CREATE","MEETINGS_EDIT",'
      '"MEETINGS_DELETE","ATTENDANCE_VIEW","ATTENDANCE_EDIT","FOLLOWUPS_VIEW","FOLLOWUPS_CREATE",'
      '"MEMBERS_REGISTER","MEMBERS_REMOVE","CELL_REPORTS_VIEW","CELL_REPORTS_CREATE"],'
      '"leads_cells":1,"scope":{"scope":"OWN_CELL","church_wide":false,"cell_ids":[1],'
      '"leads_cell_ids":[1],"coordinates_cell_ids":[]}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    String responseString = '[]';
    int statusCode = 200;

    // Las rutas de gestión de célula se resuelven antes que el `/cells/`
    // genérico, que si no se las tragaría todas.
    if (path.contains('/cells/my-cells/')) {
      responseString = asLeader
          ? '{"scope":{"scope":"OWN_CELL","church_wide":false,"cell_ids":[1],'
              '"leads_cell_ids":[1],"coordinates_cell_ids":[]},'
              '"results":[{"id":1,"name":"Célula Norte","slug":"celula-norte",'
              '"meeting_day":"MONDAY","meeting_time":"19:00:00","address":"Calle 1",'
              '"status":"ACTIVE"}]}'
          : '{"scope":{"scope":"SELF","church_wide":false,"cell_ids":[],'
              '"leads_cell_ids":[],"coordinates_cell_ids":[]},"results":[]}';
    } else if (path.contains('/statistics/')) {
      responseString = '{"cell":{"id":1,"name":"Célula Norte","slug":"celula-norte"},'
          '"members_total":3,"members_active":3,"members_inactive":0,"meetings_total":2,'
          '"average_attendance":2.5,'
          '"attendance_by_status":{"PRESENT":4,"ABSENT":1,"LATE":1,"EXCUSED":0},'
          '"attendance_trend":[{"date":"2026-08-03","attendees":2,"topic":"Fe"}],'
          '"needs_attention":1}';
    } else if (path.contains('/members/')) {
      responseString = '{"cell":{"id":1,"name":"Célula Norte","slug":"celula-norte"},"count":1,'
          '"results":[{"id":30,"email":"ana@iglesia.org","first_name":"Ana","last_name":"Quispe",'
          '"full_name":"Ana Quispe","phone":"+51999","location":"","status":"ACTIVE"}]}';
    } else if (path.contains('/cell-meetings/')) {
      responseString = '{"count":1,"next":null,"results":[{"id":12,"cell":1,'
          '"cell_name":"Célula Norte","date":"2026-08-03","time":"19:00:00","topic":"Fe",'
          '"notes":"","guests_count":0,"attendees_count":2,"attendances":['
          '{"id":1,"member":{"id":30,"full_name":"Ana Quispe","email":"ana@iglesia.org"},'
          '"status":"PRESENT","status_display":"Asistió","notes":""},'
          '{"id":2,"member":{"id":31,"full_name":"Luis Rojas","email":"luis@iglesia.org"},'
          '"status":"LATE","status_display":"Tardanza","notes":""}]}]}';
    } else if (path.contains('/cell-follow-ups/')) {
      responseString = '{"count":1,"next":null,"results":[{"id":5,"cell":1,'
          '"member":{"id":30,"full_name":"Ana Quispe","email":"ana@iglesia.org"},'
          '"type":"CALL","type_display":"Llamada","date":"2026-08-05",'
          '"summary":"Se le llamó para animarla.","needs_attention":false}]}';
    } else if (path.contains('/cell-reports/')) {
      // El primero es de un día, como los que se redactan ahora. El segundo
      // conserva un periodo, como los que ya se entregaron antes del cambio.
      responseString = '{"count":2,"next":null,"results":['
          '{"id":9,"cell":1,"cell_name":"Célula Norte",'
          '"period_start":"2026-08-03","period_end":"2026-08-03",'
          '"summary":"Buen mes.","status":"DRAFT","status_display":"Borrador"},'
          '{"id":8,"cell":1,"cell_name":"Célula Norte",'
          '"period_start":"2026-07-01","period_end":"2026-07-31",'
          '"summary":"Mes anterior.","status":"REVIEWED","status_display":"Revisado"}]}';
    } else if (path.contains('/settings/public/')) {
      responseString = '{"app":{"app_name":"Génesis","app_description":"","splash_text":"","primary_color":"#000000","secondary_color":"#ffffff"},"church":{"church_name":"Iglesia","address":"","city":"","country":"","email":"","website":"","whatsapp":""},"schedules":[],"social_networks":[]}';
    } else if (path.contains('/devotionals/today/')) {
      responseString = '{"id":1,"title":"Devocional","slug":"dev","content":"Content","verse_reference":"","verse_text":"","date":"2026-07-10"}';
    } else if (path.contains('/auth/me/')) {
      responseString = '{"id":1,"email":"t@t.com","first_name":"Test","last_name":"User",'
          '"full_name":"Test User","phone":"","status":"ACTIVE"'
          '${asLeader ? ',$_leaderScope' : ''}}';
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
  Widget createTestWidget(Widget child, {bool authenticated = true, bool asLeader = false}) {
    final dio = Dio();
    dio.options.baseUrl = 'http://localhost:8000/api/v1';
    dio.httpClientAdapter = MockAdapter(asLeader: asLeader);

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

  /// Deja terminar las peticiones encadenadas: sesión → células a cargo →
  /// datos de la célula.
  ///
  /// `pumpAndSettle` vuelve en cuanto no queda ningún fotograma pendiente, y
  /// entre una petición y la siguiente hay instantes en los que no lo hay: sin
  /// esto la pantalla se comprobaba a mitad de la cadena.
  Future<void> settleRequests(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
  }

  group('Gestión de célula', () {
    testWidgets('Mi Célula muestra la célula a cargo y sus accesos', (tester) async {
      await tester.pumpWidget(createTestWidget(const LeaderHomePage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Célula Norte'), findsOneWidget);
      expect(find.text('Miembros'), findsOneWidget);
      expect(find.text('Reuniones y asistencia'), findsOneWidget);

      // El resto de accesos queda bajo el pliegue en una pantalla de teléfono.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Seguimientos'), findsOneWidget);
      expect(find.text('Informes de actividad'), findsOneWidget);
      expect(find.text('Enviar un aviso'), findsOneWidget);
    });

    testWidgets('sin célula a cargo se explica en lugar de quedarse en blanco', (tester) async {
      // Un miembro corriente: no tiene ninguna célula que gestionar.
      await tester.pumpWidget(createTestWidget(const LeaderHomePage()));
      await settleRequests(tester);

      expect(find.textContaining('no tienes una célula a tu cargo'), findsOneWidget);
    });

    testWidgets('la lista de miembros carga a los integrantes', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellMembersPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Ana Quispe'), findsOneWidget);
      // Con permiso de alta, el botón para añadir está disponible.
      expect(find.text('AÑADIR'), findsOneWidget);
    });

    testWidgets('las reuniones se listan con su asistencia', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellMeetingsPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Fe'), findsOneWidget);
      expect(find.text('2 asistente(s)'), findsOneWidget);
      expect(find.text('Pasar lista'), findsOneWidget);
    });

    testWidgets('los seguimientos se listan', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellFollowUpsPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Ana Quispe'), findsOneWidget);
      expect(find.textContaining('Llamada'), findsOneWidget);
    });

    testWidgets('un informe en borrador ofrece editarlo y enviarlo', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellReportsPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Buen mes.'), findsOneWidget);
      // Sólo el borrador se puede enviar; el ya revisado, no.
      expect(find.text('ENVIAR'), findsOneWidget);
      expect(find.text('EDITAR'), findsOneWidget);
    });

    testWidgets('el informe se identifica por su día, no por un periodo', (tester) async {
      // El líder informa de un día concreto —el de la reunión—, así que la
      // tarjeta lo dice tal cual en lugar de repetir la misma fecha dos veces.
      await tester.pumpWidget(createTestWidget(const CellReportsPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Lunes 3 de agosto'), findsOneWidget);
    });

    testWidgets('los informes entregados con periodo siguen mostrándolo', (tester) async {
      // Los que se enviaron antes del cambio no se reescriben ni se falsean.
      await tester.pumpWidget(createTestWidget(const CellReportsPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('01/07/2026 — 31/07/2026'), findsOneWidget);
    });

    testWidgets('el aviso dice a cuánta gente va a llegar', (tester) async {
      await tester.pumpWidget(createTestWidget(const CellAnnouncementPage(), asLeader: true));
      await settleRequests(tester);

      expect(find.textContaining('1 persona(s) de Célula Norte'), findsOneWidget);
      expect(find.text('ENVIAR AHORA'), findsOneWidget);
    });

    testWidgets('el perfil no repite la gestión: el líder la tiene en su pestaña', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfilePage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Células de la iglesia'), findsNothing);
      // Lo suyo de miembro sigue estando.
      expect(find.text('Editar Perfil'), findsOneWidget);
    });

    testWidgets('el perfil de un miembro corriente tampoco la ofrece', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfilePage()));
      await settleRequests(tester);

      expect(find.text('Células de la iglesia'), findsNothing);
    });
  });

  group('El inicio cambia según de quién responde', () {
    testWidgets('el miembro conserva su inicio de siempre', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomePage()));
      await settleRequests(tester);

      expect(find.text('Noticias'), findsOneWidget);
      expect(find.text('Conectar'), findsNothing);
      // Nada de la gestión de célula se le cuela.
      expect(find.textContaining('tu célula'), findsNothing);
    });

    testWidgets('el líder abre en su célula, no en la cuadrícula de la iglesia', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomePage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('Célula Norte'), findsOneWidget);
      expect(find.text('Esto es lo que pasa con tu célula.'), findsOneWidget);
      expect(find.text('Enviar aviso'), findsOneWidget);
    });

    testWidgets('el inicio del líder avisa de lo que quedó pendiente', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomePage(), asLeader: true));
      await settleRequests(tester);

      expect(find.text('PENDIENTE'), findsOneWidget);
      // El informe de la respuesta simulada está en borrador.
      expect(find.textContaining('informe en borrador'), findsOneWidget);
      // Y una persona figura como que necesita atención.
      expect(find.textContaining('necesita atención cercana'), findsOneWidget);
    });

    testWidgets('lo de la iglesia sigue a mano para el líder', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomePage(), asLeader: true));
      await settleRequests(tester);

      // Al ceder «Conectar» su sitio en la barra, estos accesos se quedarían
      // sin puerta si no estuvieran aquí.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('DE LA IGLESIA'), findsOneWidget);
      expect(find.text('Oración'), findsOneWidget);
      expect(find.text('Contacto'), findsOneWidget);
      expect(find.text('Devocionales'), findsOneWidget);
    });
  });
}
