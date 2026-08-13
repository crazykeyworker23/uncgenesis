import '../../data/models/leader_models.dart';

/// Todo lo que un líder hace con su célula desde el teléfono.
///
/// El servidor decide siempre quién puede qué: cada endpoint comprueba que la
/// célula esté a cargo de quien pide la operación. Aquí sólo se describe la
/// conversación.
abstract class LeaderRepository {
  /// Células que la sesión tiene a su cargo, con su alcance.
  Future<MyCells> getMyCells();

  Future<CellStatistics> getStatistics(int cellId);

  Future<List<CellMember>> getMembers(int cellId);

  /// Da de alta a un integrante o visitante. Devuelve el aviso del servidor.
  Future<String> registerMember(
    int cellId, {
    required String firstName,
    String lastName,
    String email,
    String phone,
    String location,
  });

  /// Retira a alguien de la célula sin borrar su cuenta.
  Future<String> removeMember(int cellId, int memberId);

  /// Envía —o programa— un aviso desde la célula.
  ///
  /// [recipient] elige a cuál de los tres interlocutores va: su gente, quien
  /// le supervisa o el pastorado. Ver [ReminderRecipient].
  Future<String> sendReminder(
    int cellId, {
    String title,
    required String body,
    DateTime? scheduledFor,
    String recipient,
  });

  Future<Paged<CellMeeting>> getMeetings(int cellId, {int page});

  /// Una reunión concreta con su lista de asistencia ya pasada.
  Future<CellMeeting> getMeeting(int meetingId);

  Future<CellMeeting> createMeeting({
    required int cellId,
    required String date,
    String? time,
    String topic,
    String notes,
    int guestsCount,
  });

  Future<CellMeeting> updateMeeting(
    int meetingId, {
    required String date,
    String? time,
    String topic,
    String notes,
    int guestsCount,
  });

  Future<void> deleteMeeting(int meetingId);

  /// Guarda el pase de lista completo. Devuelve cuántos asistieron.
  Future<int> saveAttendance(int meetingId, List<AttendanceDraft> attendances);

  Future<Paged<MemberFollowUp>> getFollowUps(int cellId, {int page});

  Future<MemberFollowUp> createFollowUp({
    required int cellId,
    required int memberId,
    required String type,
    required String date,
    required String summary,
    bool needsAttention,
  });

  Future<void> deleteFollowUp(int followUpId);

  Future<Paged<CellReport>> getReports(int cellId, {int page});

  /// Guarda el informe como borrador. `photoPath` adjunta una foto del equipo.
  Future<CellReport> saveReport({
    required int cellId,
    int? reportId,
    required String periodStart,
    required String periodEnd,
    required String summary,
    String highlights,
    String challenges,
    String prayerNeeds,
    String photoCaption,
    String? photoPath,
  });

  /// Entrega el informe a la supervisión y congela sus cifras.
  Future<CellReport> sendReport(int reportId);

  Future<void> deleteReport(int reportId);
}
