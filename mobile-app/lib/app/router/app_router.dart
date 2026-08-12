import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/publications/presentation/pages/publications_page.dart';
import '../../features/publications/presentation/pages/publication_detail_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/services/presentation/pages/service_detail_page.dart';
import '../../features/devotionals/presentation/pages/devotionals_page.dart';
import '../../features/devotionals/presentation/pages/devotional_detail_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/cells/presentation/pages/cells_page.dart';
import '../../features/cells/presentation/pages/cell_detail_page.dart';
import '../../features/requests/presentation/pages/connect_page.dart';
import '../../features/requests/presentation/pages/prayer_request_page.dart';
import '../../features/requests/presentation/pages/visitor_request_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/leader/presentation/pages/leader_home_page.dart';
import '../../features/leader/presentation/pages/cell_members_page.dart';
import '../../features/leader/presentation/pages/cell_meetings_page.dart';
import '../../features/leader/presentation/pages/cell_attendance_page.dart';
import '../../features/leader/presentation/pages/cell_follow_ups_page.dart';
import '../../features/leader/presentation/pages/cell_reports_page.dart';
import '../../features/leader/presentation/pages/cell_announcement_page.dart';
import '../../features/leader/presentation/widgets/leader_widgets.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/saved_devotionals_page.dart';
import '../../features/profile/presentation/pages/my_events_page.dart';
import '../../features/profile/presentation/pages/my_requests_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import 'main_shell_layout.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/auth/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/auth/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/auth/forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordPage();
      },
    ),
    
    // Bottom Navigation Shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainShellLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/events',
          builder: (BuildContext context, GoRouterState state) {
            return const EventsPage();
          },
        ),
        GoRoute(
          path: '/publications',
          builder: (BuildContext context, GoRouterState state) {
            return const PublicationsPage();
          },
        ),
        GoRoute(
          path: '/connect',
          builder: (BuildContext context, GoRouterState state) {
            return const ConnectPage();
          },
        ),
        // Pestaña de quien responde de una célula. Va dentro del armazón para
        // que conserve la barra inferior: es una sección de la aplicación, no
        // una pantalla que se abre encima y de la que hay que volver.
        GoRoute(
          path: '/leader',
          builder: (BuildContext context, GoRouterState state) {
            return const LeaderHomePage();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfilePage();
          },
        ),
      ],
    ),

    // Full screen sub-routes / detail pages (open on root navigator to cover bottom bar)
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/publications/:slug',
      builder: (BuildContext context, GoRouterState state) {
        final slug = state.pathParameters['slug'] ?? '';
        return PublicationDetailPage(slug: slug);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/services',
      builder: (BuildContext context, GoRouterState state) {
        return const ServicesPage();
      },
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ':slug',
          builder: (BuildContext context, GoRouterState state) {
            final slug = state.pathParameters['slug'] ?? '';
            return ServiceDetailPage(slug: slug);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/devotionals',
      builder: (BuildContext context, GoRouterState state) {
        return const DevotionalsPage();
      },
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ':slug',
          builder: (BuildContext context, GoRouterState state) {
            final slug = state.pathParameters['slug'] ?? '';
            return DevotionalDetailPage(slug: slug);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/events/:slug',
      builder: (BuildContext context, GoRouterState state) {
        final slug = state.pathParameters['slug'] ?? '';
        return EventDetailPage(slug: slug);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/cells',
      builder: (BuildContext context, GoRouterState state) {
        return const CellsPage();
      },
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ':id',
          builder: (BuildContext context, GoRouterState state) {
            final id = state.pathParameters['id'] ?? '';
            return CellDetailPage(id: id);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/connect/prayer',
      builder: (BuildContext context, GoRouterState state) {
        return const PrayerRequestPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/requests/prayer',
      builder: (BuildContext context, GoRouterState state) {
        return const PrayerRequestPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/connect/visitor',
      builder: (BuildContext context, GoRouterState state) {
        return const VisitorRequestPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/requests/visitor',
      builder: (BuildContext context, GoRouterState state) {
        return const VisitorRequestPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile/edit',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileEditPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile/saved-devotionals',
      builder: (BuildContext context, GoRouterState state) {
        return const SavedDevotionalsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile/my-events',
      builder: (BuildContext context, GoRouterState state) {
        return const MyEventsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile/my-requests',
      builder: (BuildContext context, GoRouterState state) {
        return const MyRequestsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),

    // ── Gestión de célula ───────────────────────────────────────────────────
    // El índice de la sección («/leader») es una pestaña y vive en el armazón,
    // más arriba. Estas pantallas se abren encima, a pantalla completa, porque
    // son tareas concretas de las que se vuelve.
    //
    // Sólo las alcanza quien tiene células a su cargo, y cada una lo vuelve a
    // comprobar. Aun así, el servidor rechaza toda operación fuera de alcance:
    // escribir la ruta a mano no da acceso a nada.
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/members',
      builder: (BuildContext context, GoRouterState state) {
        return const CellMembersPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/meetings',
      builder: (BuildContext context, GoRouterState state) {
        return const CellMeetingsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/meetings/:id/attendance',
      builder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const LeaderMissingCellScaffold(title: 'Asistencia');
        }
        return CellAttendancePage(meetingId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/follow-ups',
      builder: (BuildContext context, GoRouterState state) {
        return const CellFollowUpsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/reports',
      builder: (BuildContext context, GoRouterState state) {
        return const CellReportsPage();
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/leader/announce',
      builder: (BuildContext context, GoRouterState state) {
        return const CellAnnouncementPage();
      },
    ),
  ],
);
