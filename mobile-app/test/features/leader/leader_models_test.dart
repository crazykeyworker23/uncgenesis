import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/features/auth/data/models/user_model.dart';
import 'package:genesis_app/features/leader/data/models/leader_models.dart';

void main() {
  group('Alcance sobre las células', () {
    test('pertenecer a una célula no es tenerla a cargo', () {
      // Es el caso del miembro corriente: el servidor lo deja alcanzar su
      // célula, y sin distinguirlo la gestión se le ofrecería a media iglesia.
      const scope = SessionScope(level: 'SELF', cellIds: [7]);

      expect(scope.canReach(7), isTrue);
      expect(scope.canManage(7), isFalse);
      expect(scope.managesAnyCell, isFalse);
    });

    test('el líder gestiona la célula que lidera y ninguna otra', () {
      const scope = SessionScope(level: 'OWN_CELL', cellIds: [7], ledCellIds: [7]);

      expect(scope.canManage(7), isTrue);
      expect(scope.canManage(8), isFalse);
      expect(scope.managesAnyCell, isTrue);
    });

    test('el coordinador gestiona las que supervisa', () {
      const scope = SessionScope(
        level: 'ASSIGNED_CELLS',
        cellIds: [3, 4],
        coordinatedCellIds: [3, 4],
      );

      expect(scope.canManage(3), isTrue);
      expect(scope.canManage(9), isFalse);
    });

    test('el pastorado alcanza y gestiona cualquier célula', () {
      // Con alcance de iglesia el servidor no envía la lista: son todas.
      const scope = SessionScope(level: 'CHURCH', churchWide: true);

      expect(scope.canReach(99), isTrue);
      expect(scope.canManage(99), isTrue);
      expect(scope.managesAnyCell, isTrue);
    });
  });

  group('Responsabilidad propia sobre un grupo', () {
    // Decide cómo se ordena la aplicación: la barra inferior y el inicio
    // cambian para quien responde de una célula concreta, no para quien las
    // alcanza todas por su cargo.

    test('el líder responde de su célula', () {
      const scope = SessionScope(cellIds: [7], ledCellIds: [7]);
      expect(scope.hasOwnCells, isTrue);
    });

    test('el coordinador responde de las que supervisa', () {
      const scope = SessionScope(cellIds: [3, 4], coordinatedCellIds: [3, 4]);
      expect(scope.hasOwnCells, isTrue);
    });

    test('el pastorado no: en el teléfono es un miembro más', () {
      // Alcanza todas las células, pero su herramienta de administración es el
      // panel. Reordenarle la app no le ayudaría en nada.
      const scope = SessionScope(level: 'CHURCH', churchWide: true);

      expect(scope.managesAnyCell, isTrue);
      expect(scope.hasOwnCells, isFalse);
    });

    test('el miembro tampoco, aunque pertenezca a una célula', () {
      const scope = SessionScope(level: 'SELF', cellIds: [7]);
      expect(scope.hasOwnCells, isFalse);
    });
  });

  group('Perfil de la sesión', () {
    test('lee roles, permisos y alcance de /auth/me/', () {
      final user = UserModel.fromJson({
        'id': 5,
        'email': 'lider@iglesia.org',
        'full_name': 'Ana Quispe',
        'status': 'ACTIVE',
        'roles': ['CELL_LEADER'],
        'permissions': ['MEETINGS_CREATE', 'ATTENDANCE_EDIT'],
        'leads_cells': 1,
        'scope': {
          'scope': 'OWN_CELL',
          'church_wide': false,
          'cell_ids': [7],
          'leads_cell_ids': [7],
          'coordinates_cell_ids': <int>[],
        },
      });

      expect(user.roles, ['CELL_LEADER']);
      expect(user.can('ATTENDANCE_EDIT'), isTrue);
      expect(user.can('CELLS_DELETE'), isFalse);
      expect(user.canAny(['CELLS_DELETE', 'MEETINGS_CREATE']), isTrue);
      expect(user.leadsAnyCell, isTrue);
      expect(user.scope.canManage(7), isTrue);
    });

    test('un miembro de célula no obtiene la sección de gestión', () {
      final user = UserModel.fromJson({
        'id': 9,
        'email': 'miembro@iglesia.org',
        'full_name': 'Luis Rojas',
        'status': 'ACTIVE',
        'roles': ['MEMBER'],
        'permissions': <String>[],
        'leads_cells': 0,
        'scope': {
          'scope': 'SELF',
          'church_wide': false,
          'cell_ids': [7],
          'leads_cell_ids': <int>[],
          'coordinates_cell_ids': <int>[],
        },
      });

      expect(user.leadsAnyCell, isFalse);
    });

    test('una respuesta sin roles ni alcance no rompe el perfil', () {
      // El perfil también se actualiza con PATCH y puede volver recortado.
      final user = UserModel.fromJson({
        'id': 1,
        'email': 'x@y.org',
        'full_name': 'Sin Datos',
        'status': 'ACTIVE',
      });

      expect(user.roles, isEmpty);
      expect(user.permissions, isEmpty);
      expect(user.leadsAnyCell, isFalse);
      expect(user.can('MEETINGS_CREATE'), isFalse);
    });
  });

  group('Lectura de las respuestas del servidor', () {
    test('una reunión trae su asistencia y se consulta por persona', () {
      final meeting = CellMeeting.fromJson({
        'id': 12,
        'cell': 7,
        'cell_name': 'Célula Norte',
        'date': '2026-08-04',
        'time': '19:00:00',
        'topic': 'La oración',
        'guests_count': 2,
        'attendees_count': 6,
        'attendances': [
          {
            'id': 1,
            'member': {'id': 30, 'full_name': 'Ana Q.', 'email': 'ana@x.org'},
            'status': 'PRESENT',
            'status_display': 'Asistió',
          },
          {
            'id': 2,
            'member': {'id': 31, 'full_name': 'Luis R.', 'email': 'luis@x.org'},
            'status': 'LATE',
            'status_display': 'Tardanza',
          },
        ],
      });

      expect(meeting.hasAttendance, isTrue);
      expect(meeting.statusFor(30), AttendanceStatus.present);
      expect(meeting.statusFor(31), AttendanceStatus.late);
      // Quien no aparece es que no se le pasó lista, no que faltara.
      expect(meeting.statusFor(99), isNull);
    });

    test('una reunión sin lista pasada se distingue de una vacía', () {
      final meeting = CellMeeting.fromJson({'id': 13, 'cell': 7, 'date': '2026-08-11'});

      expect(meeting.hasAttendance, isFalse);
      expect(meeting.attendeesCount, 0);
      expect(meeting.time, isNull);
    });

    test('las estadísticas traen el desglose y la evolución', () {
      final stats = CellStatistics.fromJson({
        'members_total': 10,
        'members_active': 8,
        'members_inactive': 2,
        'meetings_total': 4,
        'average_attendance': 6.5,
        'attendance_by_status': {'PRESENT': 20, 'ABSENT': 4, 'LATE': 3, 'EXCUSED': 1},
        'attendance_trend': [
          {'date': '2026-07-28', 'attendees': 5, 'topic': 'Fe'},
          {'date': '2026-08-04', 'attendees': 7, 'topic': 'Oración'},
        ],
        'needs_attention': 2,
      });

      expect(stats.membersActive, 8);
      expect(stats.averageAttendance, 6.5);
      expect(stats.attendanceByStatus['PRESENT'], 20);
      expect(stats.attendanceTrend.length, 2);
      expect(stats.attendanceTrend.last.attendees, 7);
    });

    test('un informe en borrador se puede editar; uno enviado no', () {
      final draft = CellReport.fromJson({
        'id': 1,
        'cell': 7,
        'period_start': '2026-07-01',
        'period_end': '2026-07-31',
        'summary': 'Buen mes',
        'status': 'DRAFT',
      });
      final sent = CellReport.fromJson({
        'id': 2,
        'cell': 7,
        'period_start': '2026-06-01',
        'period_end': '2026-06-30',
        'summary': 'Mes anterior',
        'status': 'REVIEWED',
        'review_notes': 'Muy bien, sigan así.',
        'reviewed_by': {'id': 3, 'full_name': 'Pastor Díaz', 'email': 'p@x.org'},
      });

      expect(draft.isDraft, isTrue);
      expect(draft.hasReply, isFalse);
      expect(sent.isDraft, isFalse);
      expect(sent.hasReply, isTrue);
      expect(sent.reviewedBy?.fullName, 'Pastor Díaz');
    });

    test('el visitante sin correo no enseña el que le inventó el servidor', () {
      final visitor = CellMember.fromJson({
        'id': 40,
        'email': 'visitante.norte.20260804@genesis.local',
        'first_name': 'María',
        'last_name': '',
        'status': 'ACTIVE',
      });

      expect(visitor.fullName, 'María');
      expect(visitor.hasRealEmail, isFalse);
      expect(visitor.initials, 'M');
    });

    test('una página indica si quedan más resultados', () {
      final first = Paged<CellReport>.fromJson({
        'count': 14,
        'next': 'http://servidor/api/v1/cell-reports/?page=2',
        'results': [
          {'id': 1, 'cell': 7, 'period_start': '2026-07-01', 'period_end': '2026-07-31'},
        ],
      }, CellReport.fromJson);

      final last = Paged<CellReport>.fromJson({
        'count': 14,
        'next': null,
        'results': <Map<String, dynamic>>[],
      }, CellReport.fromJson);

      expect(first.hasMore, isTrue);
      expect(first.count, 14);
      expect(last.hasMore, isFalse);
    });

    test('un número que llega como texto no rompe la pantalla', () {
      final stats = CellStatistics.fromJson({
        'members_total': '10',
        'average_attendance': '6.5',
      });

      expect(stats.membersTotal, 10);
      expect(stats.averageAttendance, 6.5);
    });
  });

  group('Pase de lista', () {
    test('la marca se envía con el formato que espera el servidor', () {
      const draft = AttendanceDraft(memberId: 30, status: AttendanceStatus.late);

      expect(draft.toJson(), {'member_id': 30, 'status': 'LATE'});
    });

    test('una nota en blanco no se envía', () {
      const draft = AttendanceDraft(memberId: 30, status: 'PRESENT', notes: '   ');

      expect(draft.toJson().containsKey('notes'), isFalse);
    });

    test('están los cuatro estados del sistema', () {
      expect(AttendanceStatus.all.length, 4);
      expect(AttendanceStatus.label(AttendanceStatus.excused), 'Justificado');
      expect(AttendanceStatus.label(null), 'Sin registrar');
    });
  });

  group('Células a cargo', () {
    test('separa las que se gestionan de las que sólo se consultan', () {
      final response = MyCells.fromJson({
        'scope': {
          'scope': 'ASSIGNED_CELLS',
          'church_wide': false,
          'cell_ids': [3, 7],
          'leads_cell_ids': <int>[],
          'coordinates_cell_ids': [3],
        },
        'results': [
          {'id': 3, 'name': 'Norte', 'slug': 'norte', 'meeting_day': 'MONDAY',
           'meeting_time': '19:00:00', 'address': 'x', 'status': 'ACTIVE'},
          {'id': 7, 'name': 'Sur', 'slug': 'sur', 'meeting_day': 'FRIDAY',
           'meeting_time': '20:00:00', 'address': 'y', 'status': 'ACTIVE'},
        ],
      });

      expect(response.cells.length, 2);
      expect(response.managed.map((c) => c.id), [3]);
      expect(response.cells.first.dayLabel, 'Lunes');
    });
  });
}
