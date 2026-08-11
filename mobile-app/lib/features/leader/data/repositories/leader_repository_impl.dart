import 'package:dio/dio.dart';

import '../../domain/repositories/leader_repository.dart';
import '../models/leader_models.dart';

class LeaderRepositoryImpl implements LeaderRepository {
  final Dio _dio;

  LeaderRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<MyCells> getMyCells() async {
    final response = await _dio.get('/cells/my-cells/');
    return MyCells.fromJson(_asMap(response.data));
  }

  @override
  Future<CellStatistics> getStatistics(int cellId) async {
    final response = await _dio.get('/cells/$cellId/statistics/');
    return CellStatistics.fromJson(_asMap(response.data));
  }

  @override
  Future<List<CellMember>> getMembers(int cellId) async {
    final response = await _dio.get('/cells/$cellId/members/');
    final data = _asMap(response.data);
    final results = data['results'];
    if (results is! List) return const [];
    return results.whereType<Map>().map((e) => CellMember.fromJson(_asMap(e))).toList();
  }

  @override
  Future<String> registerMember(
    int cellId, {
    required String firstName,
    String lastName = '',
    String email = '',
    String phone = '',
    String location = '',
  }) async {
    final response = await _dio.post('/cells/$cellId/register-member/', data: {
      'first_name': firstName.trim(),
      if (lastName.trim().isNotEmpty) 'last_name': lastName.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (location.trim().isNotEmpty) 'location': location.trim(),
    });
    return _detail(response.data, fallback: 'Integrante registrado.');
  }

  @override
  Future<String> removeMember(int cellId, int memberId) async {
    final response = await _dio.post(
      '/cells/$cellId/remove-member/',
      data: {'member_id': memberId},
    );
    return _detail(response.data, fallback: 'La persona ya no pertenece a la célula.');
  }

  @override
  Future<String> sendReminder(
    int cellId, {
    String title = '',
    required String body,
    DateTime? scheduledFor,
  }) async {
    final response = await _dio.post('/cells/$cellId/send-reminder/', data: {
      if (title.trim().isNotEmpty) 'title': title.trim(),
      'body': body.trim(),
      // El servidor entiende «sin fecha» como enviar ahora mismo.
      if (scheduledFor != null) 'scheduled_for': scheduledFor.toUtc().toIso8601String(),
    });
    return _detail(response.data, fallback: 'Aviso enviado a tu célula.');
  }

  @override
  Future<Paged<CellMeeting>> getMeetings(int cellId, {int page = 1}) async {
    final response = await _dio.get('/cell-meetings/', queryParameters: {
      'cell': cellId,
      'page': page,
    });
    return Paged.fromJson(_asMap(response.data), CellMeeting.fromJson);
  }

  @override
  Future<CellMeeting> getMeeting(int meetingId) async {
    final response = await _dio.get('/cell-meetings/$meetingId/');
    return CellMeeting.fromJson(_asMap(response.data));
  }

  @override
  Future<CellMeeting> createMeeting({
    required int cellId,
    required String date,
    String? time,
    String topic = '',
    String notes = '',
    int guestsCount = 0,
  }) async {
    final response = await _dio.post('/cell-meetings/', data: {
      'cell': cellId,
      'date': date,
      if (time != null && time.isNotEmpty) 'time': time,
      'topic': topic.trim(),
      'notes': notes.trim(),
      'guests_count': guestsCount,
    });
    return CellMeeting.fromJson(_asMap(response.data));
  }

  @override
  Future<CellMeeting> updateMeeting(
    int meetingId, {
    required String date,
    String? time,
    String topic = '',
    String notes = '',
    int guestsCount = 0,
  }) async {
    final response = await _dio.patch('/cell-meetings/$meetingId/', data: {
      'date': date,
      // Enviar `null` borra la hora registrada, que es justo lo que se espera
      // al dejar el campo vacío.
      'time': (time != null && time.isNotEmpty) ? time : null,
      'topic': topic.trim(),
      'notes': notes.trim(),
      'guests_count': guestsCount,
    });
    return CellMeeting.fromJson(_asMap(response.data));
  }

  @override
  Future<void> deleteMeeting(int meetingId) async {
    await _dio.delete('/cell-meetings/$meetingId/');
  }

  @override
  Future<int> saveAttendance(int meetingId, List<AttendanceDraft> attendances) async {
    final response = await _dio.post(
      '/cell-meetings/$meetingId/attendance/',
      data: {'attendances': attendances.map((a) => a.toJson()).toList()},
    );
    final data = _asMap(response.data);
    final count = data['attendees_count'];
    return count is int ? count : int.tryParse('$count') ?? 0;
  }

  @override
  Future<Paged<MemberFollowUp>> getFollowUps(int cellId, {int page = 1}) async {
    final response = await _dio.get('/cell-follow-ups/', queryParameters: {
      'cell': cellId,
      'page': page,
    });
    return Paged.fromJson(_asMap(response.data), MemberFollowUp.fromJson);
  }

  @override
  Future<MemberFollowUp> createFollowUp({
    required int cellId,
    required int memberId,
    required String type,
    required String date,
    required String summary,
    bool needsAttention = false,
  }) async {
    final response = await _dio.post('/cell-follow-ups/', data: {
      'cell': cellId,
      'member_id': memberId,
      'type': type,
      'date': date,
      'summary': summary.trim(),
      'needs_attention': needsAttention,
    });
    return MemberFollowUp.fromJson(_asMap(response.data));
  }

  @override
  Future<void> deleteFollowUp(int followUpId) async {
    await _dio.delete('/cell-follow-ups/$followUpId/');
  }

  @override
  Future<Paged<CellReport>> getReports(int cellId, {int page = 1}) async {
    final response = await _dio.get('/cell-reports/', queryParameters: {
      'cell': cellId,
      'page': page,
    });
    return Paged.fromJson(_asMap(response.data), CellReport.fromJson);
  }

  @override
  Future<CellReport> saveReport({
    required int cellId,
    int? reportId,
    required String periodStart,
    required String periodEnd,
    required String summary,
    String highlights = '',
    String challenges = '',
    String prayerNeeds = '',
    String photoCaption = '',
    String? photoPath,
  }) async {
    final fields = <String, dynamic>{
      'cell': cellId,
      'period_start': periodStart,
      'period_end': periodEnd,
      'summary': summary.trim(),
      'highlights': highlights.trim(),
      'challenges': challenges.trim(),
      'prayer_needs': prayerNeeds.trim(),
      'photo_caption': photoCaption.trim(),
    };

    // Con foto hay que ir en multipart; sin ella, JSON normal. Mandar siempre
    // multipart obligaría a convertir todos los números a texto.
    final Object payload;
    if (photoPath != null && photoPath.isNotEmpty) {
      payload = FormData.fromMap({
        ...fields.map((key, value) => MapEntry(key, '$value')),
        'photo': await MultipartFile.fromFile(photoPath),
      });
    } else {
      payload = fields;
    }

    final response = reportId == null
        ? await _dio.post('/cell-reports/', data: payload)
        : await _dio.patch('/cell-reports/$reportId/', data: payload);

    return CellReport.fromJson(_asMap(response.data));
  }

  @override
  Future<CellReport> sendReport(int reportId) async {
    final response = await _dio.post('/cell-reports/$reportId/send/');
    return CellReport.fromJson(_asMap(response.data));
  }

  @override
  Future<void> deleteReport(int reportId) async {
    await _dio.delete('/cell-reports/$reportId/');
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((key, value) => MapEntry(key.toString(), value));
    return <String, dynamic>{};
  }

  /// Mensaje que el servidor devuelve tras una acción, para mostrarlo tal cual.
  ///
  /// Lo redacta el backend con los datos que la app no tiene a mano —cuántos
  /// miembros recibieron el aviso, por ejemplo—, así que vale más que
  /// cualquier texto fijo aquí.
  String _detail(dynamic data, {required String fallback}) {
    final detail = _asMap(data)['detail'];
    final text = detail?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
