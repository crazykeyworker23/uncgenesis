/// Datos de la gestión de célula: quién la compone, qué reuniones se hicieron,
/// a quién se dio seguimiento y qué se informó a la supervisión.
///
/// Se escriben a mano en lugar de generarse con freezed porque varias
/// respuestas del servidor no son objetos planos —las estadísticas traen un
/// diccionario de conteos y una serie temporal— y describirlas con anotaciones
/// resultaba más enrevesado que leerlas directamente.
library;

import '../../../auth/data/models/session_scope.dart';

export '../../../auth/data/models/session_scope.dart' show SessionScope;

/// Referencia breve a una persona, tal como la devuelven las reuniones y los
/// seguimientos.
class PersonBrief {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String status;

  const PersonBrief({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.status = 'ACTIVE',
  });

  factory PersonBrief.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    return PersonBrief(
      id: _int(json['id']),
      fullName: _name(json, fallback: email),
      email: email,
      phone: _text(json['phone']),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  /// Iniciales para el avatar cuando no hay foto.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

/// Integrante de la célula, con los datos de contacto que el líder necesita.
class CellMember {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? location;
  final String status;
  final String? avatar;

  const CellMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.location,
    this.status = 'ACTIVE',
    this.avatar,
  });

  factory CellMember.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    return CellMember(
      id: _int(json['id']),
      fullName: _name(json, fallback: email),
      email: email,
      phone: _text(json['phone']),
      location: _text(json['location']),
      status: json['status'] as String? ?? 'ACTIVE',
      avatar: _text(json['avatar']),
    );
  }

  bool get isActive => status == 'ACTIVE';

  /// El servidor inventa un correo interno para el visitante que no tiene uno.
  /// Mostrarlo en pantalla sólo confunde.
  bool get hasRealEmail => !email.endsWith('@genesis.local');

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  PersonBrief get brief =>
      PersonBrief(id: id, fullName: fullName, email: email, phone: phone, status: status);
}

/// Los cuatro estados con que se pasa lista.
class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'PRESENT';
  static const String absent = 'ABSENT';
  static const String late = 'LATE';
  static const String excused = 'EXCUSED';

  static const List<String> all = [present, late, excused, absent];

  static const Map<String, String> labels = {
    present: 'Asistió',
    absent: 'No asistió',
    late: 'Tardanza',
    excused: 'Justificado',
  };

  /// Etiqueta corta para los botones del pase de lista, donde no cabe el texto
  /// completo junto a los otros tres.
  static const Map<String, String> shortLabels = {
    present: 'Asistió',
    absent: 'Faltó',
    late: 'Tarde',
    excused: 'Justif.',
  };

  static String label(String? status) => labels[status] ?? 'Sin registrar';
}

/// Asistencia de una persona a una reunión concreta.
class AttendanceEntry {
  final int id;
  final PersonBrief member;
  final String status;
  final String statusDisplay;
  final String notes;

  const AttendanceEntry({
    required this.id,
    required this.member,
    required this.status,
    required this.statusDisplay,
    this.notes = '',
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? AttendanceStatus.present;
    return AttendanceEntry(
      id: _int(json['id']),
      member: PersonBrief.fromJson(_map(json['member'])),
      status: status,
      statusDisplay: json['status_display'] as String? ?? AttendanceStatus.label(status),
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// Una marca del pase de lista, antes de guardarla.
class AttendanceDraft {
  final int memberId;
  final String status;
  final String notes;

  const AttendanceDraft({required this.memberId, required this.status, this.notes = ''});

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'status': status,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
}

/// Reunión realizada por la célula.
class CellMeeting {
  final int id;
  final int cellId;
  final String cellName;

  /// Fecha en formato ISO (`2026-08-04`), tal como la espera el servidor.
  final String date;

  /// Hora en formato `19:00:00`; puede no haberse registrado.
  final String? time;
  final String topic;
  final String notes;
  final int guestsCount;
  final int attendeesCount;
  final List<AttendanceEntry> attendances;
  final PersonBrief? registeredBy;

  const CellMeeting({
    required this.id,
    required this.cellId,
    required this.cellName,
    required this.date,
    this.time,
    this.topic = '',
    this.notes = '',
    this.guestsCount = 0,
    this.attendeesCount = 0,
    this.attendances = const [],
    this.registeredBy,
  });

  factory CellMeeting.fromJson(Map<String, dynamic> json) {
    return CellMeeting(
      id: _int(json['id']),
      cellId: _int(json['cell']),
      cellName: json['cell_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: _text(json['time']),
      topic: json['topic'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      guestsCount: _int(json['guests_count']),
      attendeesCount: _int(json['attendees_count']),
      attendances: _list(json['attendances']).map(AttendanceEntry.fromJson).toList(),
      registeredBy: json['registered_by'] == null
          ? null
          : PersonBrief.fromJson(_map(json['registered_by'])),
    );
  }

  /// `true` si ya se pasó lista en esta reunión.
  bool get hasAttendance => attendances.isNotEmpty;

  /// Estado registrado para esa persona, o `null` si no se le pasó lista.
  String? statusFor(int memberId) {
    for (final entry in attendances) {
      if (entry.member.id == memberId) return entry.status;
    }
    return null;
  }
}

/// A quién puede dirigir el líder un aviso.
///
/// Son sus tres interlocutores: su gente, quien le supervisa y el pastorado.
/// Difundir a toda la iglesia no está aquí a propósito: eso exige permisos de
/// comunicaciones que el líder no tiene, y el servidor lo rechaza.
class ReminderRecipient {
  ReminderRecipient._();

  static const String cell = 'CELL';
  static const String coordinator = 'COORDINATOR';
  static const String pastors = 'PASTORS';

  static const List<String> all = [cell, coordinator, pastors];

  static const Map<String, String> labels = {
    cell: 'Mi célula',
    coordinator: 'Mi coordinador',
    pastors: 'El pastorado',
  };

  static const Map<String, String> descriptions = {
    cell: 'A todas las personas de tu grupo',
    coordinator: 'A quien supervisa tu célula',
    pastors: 'Al pastor de la iglesia',
  };

  static String label(String? recipient) => labels[recipient] ?? 'Mi célula';
}

/// Tipos de contacto de un seguimiento pastoral.
class FollowUpType {
  FollowUpType._();

  static const String call = 'CALL';
  static const String visit = 'VISIT';
  static const String message = 'MESSAGE';
  static const String other = 'OTHER';

  static const List<String> all = [call, visit, message, other];

  static const Map<String, String> labels = {
    call: 'Llamada',
    visit: 'Visita',
    message: 'Mensaje',
    other: 'Otro',
  };

  static String label(String? type) => labels[type] ?? 'Contacto';
}

/// Contacto o visita registrada a un integrante de la célula.
class MemberFollowUp {
  final int id;
  final int cellId;
  final PersonBrief member;
  final String type;
  final String typeDisplay;
  final String date;
  final String summary;
  final bool needsAttention;
  final PersonBrief? registeredBy;

  const MemberFollowUp({
    required this.id,
    required this.cellId,
    required this.member,
    required this.type,
    required this.typeDisplay,
    required this.date,
    required this.summary,
    this.needsAttention = false,
    this.registeredBy,
  });

  factory MemberFollowUp.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? FollowUpType.call;
    return MemberFollowUp(
      id: _int(json['id']),
      cellId: _int(json['cell']),
      member: PersonBrief.fromJson(_map(json['member'])),
      type: type,
      typeDisplay: json['type_display'] as String? ?? FollowUpType.label(type),
      date: json['date'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      needsAttention: json['needs_attention'] as bool? ?? false,
      registeredBy: json['registered_by'] == null
          ? null
          : PersonBrief.fromJson(_map(json['registered_by'])),
    );
  }
}

/// De qué informa el líder.
///
/// Los dos siguen el mismo camino —borrador, enviar, respuesta del
/// coordinador—. Lo que cambia es qué se pide: el de actividad cuenta cómo fue
/// la reunión, y el de devocional es la constancia de que la célula siguió el
/// plan de lecturas, con su captura.
class CellReportKind {
  CellReportKind._();

  static const String activity = 'ACTIVITY';
  static const String devotional = 'DEVOTIONAL';

  static const Map<String, String> labels = {
    activity: 'Actividad',
    devotional: 'Devocional',
  };

  static String label(String? kind) => labels[kind] ?? 'Actividad';
}

/// Una imagen adjunta al informe.
class ReportPhoto {
  final int id;
  final String url;
  final String caption;

  const ReportPhoto({required this.id, required this.url, this.caption = ''});

  factory ReportPhoto.fromJson(Map<String, dynamic> json) => ReportPhoto(
        id: _int(json['id']),
        url: _text(json['url']) ?? '',
        caption: json['caption'] as String? ?? '',
      );
}

/// Estados por los que pasa un informe.
class CellReportStatus {
  CellReportStatus._();

  static const String draft = 'DRAFT';
  static const String sent = 'SENT';
  static const String reviewed = 'REVIEWED';

  static const Map<String, String> labels = {
    draft: 'Borrador',
    sent: 'Enviado',
    reviewed: 'Revisado',
  };

  static String label(String? status) => labels[status] ?? 'Borrador';
}

/// Informe de actividad que el líder envía a su supervisión.
class CellReport {
  final int id;
  final int cellId;
  final String cellName;
  final String periodStart;
  final String periodEnd;
  final String summary;
  final String highlights;
  final String challenges;
  final String prayerNeeds;
  final String kind;

  /// Las imágenes del informe. Hasta cinco.
  ///
  /// Antes era una sola foto: una reunión no se cuenta bien con una imagen, y
  /// el informe de devocional es justamente una captura.
  final List<ReportPhoto> photos;

  /// La foto única de los informes entregados antes del cambio.
  final String? photoUrl;
  final String photoCaption;
  final String status;
  final String statusDisplay;
  final String? sentAt;
  final PersonBrief? reviewedBy;
  final String? reviewedAt;
  final String reviewNotes;

  const CellReport({
    required this.id,
    required this.cellId,
    required this.cellName,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    this.kind = CellReportKind.activity,
    this.photos = const [],
    this.highlights = '',
    this.challenges = '',
    this.prayerNeeds = '',
    this.photoUrl,
    this.photoCaption = '',
    this.status = CellReportStatus.draft,
    this.statusDisplay = 'Borrador',
    this.sentAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes = '',
  });

  factory CellReport.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? CellReportStatus.draft;
    return CellReport(
      id: _int(json['id']),
      cellId: _int(json['cell']),
      cellName: json['cell_name'] as String? ?? '',
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      kind: json['kind'] as String? ?? CellReportKind.activity,
      photos: _list(json['photos']).map(ReportPhoto.fromJson).toList(),
      highlights: json['highlights'] as String? ?? '',
      challenges: json['challenges'] as String? ?? '',
      prayerNeeds: json['prayer_needs'] as String? ?? '',
      photoUrl: _text(json['photo_url']),
      photoCaption: json['photo_caption'] as String? ?? '',
      status: status,
      statusDisplay: json['status_display'] as String? ?? CellReportStatus.label(status),
      sentAt: _text(json['sent_at']),
      reviewedBy:
          json['reviewed_by'] == null ? null : PersonBrief.fromJson(_map(json['reviewed_by'])),
      reviewedAt: _text(json['reviewed_at']),
      reviewNotes: json['review_notes'] as String? ?? '',
    );
  }

  /// Un informe deja de poder editarse en cuanto se envía.
  bool get isDraft => status == CellReportStatus.draft;

  bool get hasReply => reviewNotes.trim().isNotEmpty;

  bool get isDevotional => kind == CellReportKind.devotional;

  /// Todo lo que hay que mostrar, contando la foto única de los antiguos.
  List<String> get imageUrls => [
        ...photos.map((p) => p.url).where((url) => url.isNotEmpty),
        if (photos.isEmpty && photoUrl != null) photoUrl!,
      ];
}

/// Un punto de la evolución de asistencia.
class AttendancePoint {
  final String date;
  final int attendees;
  final String topic;

  const AttendancePoint({required this.date, required this.attendees, this.topic = ''});

  factory AttendancePoint.fromJson(Map<String, dynamic> json) => AttendancePoint(
        date: json['date'] as String? ?? '',
        attendees: _int(json['attendees']),
        topic: json['topic'] as String? ?? '',
      );
}

/// Indicadores de la célula que el servidor calcula de una vez.
class CellStatistics {
  final int membersTotal;
  final int membersActive;
  final int membersInactive;
  final int meetingsTotal;
  final double averageAttendance;
  final Map<String, int> attendanceByStatus;
  final List<AttendancePoint> attendanceTrend;
  final int needsAttention;

  const CellStatistics({
    this.membersTotal = 0,
    this.membersActive = 0,
    this.membersInactive = 0,
    this.meetingsTotal = 0,
    this.averageAttendance = 0,
    this.attendanceByStatus = const {},
    this.attendanceTrend = const [],
    this.needsAttention = 0,
  });

  factory CellStatistics.fromJson(Map<String, dynamic> json) => CellStatistics(
        membersTotal: _int(json['members_total']),
        membersActive: _int(json['members_active']),
        membersInactive: _int(json['members_inactive']),
        meetingsTotal: _int(json['meetings_total']),
        averageAttendance: _double(json['average_attendance']),
        attendanceByStatus: _map(json['attendance_by_status'])
            .map((key, value) => MapEntry(key.toString(), _int(value))),
        attendanceTrend: _list(json['attendance_trend']).map(AttendancePoint.fromJson).toList(),
        needsAttention: _int(json['needs_attention']),
      );
}

/// Célula tal como la necesita esta sección: lo justo para identificarla y
/// mostrar cuándo se reúne.
class LeaderCell {
  final int id;
  final String name;
  final String slug;
  final String meetingDay;
  final String meetingTime;
  final String address;
  final String status;
  final String? leaderName;

  const LeaderCell({
    required this.id,
    required this.name,
    required this.slug,
    required this.meetingDay,
    required this.meetingTime,
    required this.address,
    this.status = 'ACTIVE',
    this.leaderName,
  });

  factory LeaderCell.fromJson(Map<String, dynamic> json) {
    final leader = json['leader'];
    return LeaderCell(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Célula',
      slug: json['slug'] as String? ?? '',
      meetingDay: json['meeting_day'] as String? ?? '',
      meetingTime: json['meeting_time'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      leaderName: leader is Map ? _name(_map(leader), fallback: '') : null,
    );
  }

  static const Map<String, String> _dayLabels = {
    'MONDAY': 'Lunes',
    'TUESDAY': 'Martes',
    'WEDNESDAY': 'Miércoles',
    'THURSDAY': 'Jueves',
    'FRIDAY': 'Viernes',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  String get dayLabel => _dayLabels[meetingDay] ?? meetingDay;
}

/// Respuesta de `/cells/my-cells/`.
///
/// Trae también el alcance, que es lo que distingue las células que se
/// gestionan de las que sólo se consultan.
class MyCells {
  final List<LeaderCell> cells;
  final SessionScope scope;

  const MyCells({this.cells = const [], this.scope = const SessionScope()});

  factory MyCells.fromJson(Map<String, dynamic> json) => MyCells(
        cells: _list(json['results']).map(LeaderCell.fromJson).toList(),
        scope: SessionScope.fromJson(_map(json['scope'])),
      );

  /// Células sobre las que además se puede escribir.
  List<LeaderCell> get managed =>
      cells.where((cell) => scope.canManage(cell.id)).toList(growable: false);
}

/// Página de una lista paginada del servidor (`count`, `next`, `results`).
class Paged<T> {
  final List<T> items;
  final int count;
  final bool hasMore;

  const Paged({this.items = const [], this.count = 0, this.hasMore = false});

  factory Paged.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    // Un endpoint sin paginar devuelve la lista pelada; conviene aceptar ambas
    // formas para no depender de la configuración del servidor.
    //
    // El tipo se escribe entero: `const Paged(...)` construiría un
    // `Paged<Never>` porque en contexto constante Dart no puede quedarse con
    // la `T` de esta clase.
    if (json['results'] is! List && json.isEmpty) {
      return Paged<T>(items: <T>[], count: 0, hasMore: false);
    }
    final items = _list(json['results']).map(parse).toList();
    return Paged(
      items: items,
      count: _int(json['count']),
      hasMore: _text(json['next']) != null,
    );
  }
}

// ── Lectura tolerante de la respuesta ───────────────────────────────────────
// El servidor puede omitir un campo opcional o devolver un número como texto.
// Estas ayudas evitan que eso reviente la pantalla entera.

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String? _text(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_map).toList();
}

/// Nombre completo con respaldo: el servidor lo envía ya compuesto, pero si
/// faltara se arma con nombre y apellido.
String _name(Map<String, dynamic> json, {required String fallback}) {
  final full = _text(json['full_name']);
  if (full != null) return full;
  final composed =
      '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');
  return composed.isNotEmpty ? composed : fallback;
}
