import 'package:dio/dio.dart';
import '../../domain/repositories/requests_repository.dart';
import '../models/requests_model.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  final Dio _dio;

  RequestsRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<void> submitPrayerRequest(PrayerRequestModel request) async {
    await _dio.post('/prayer-requests/', data: request.toJson());
  }

  @override
  Future<void> submitVisitorRequest(VisitorRequestModel request) async {
    await _dio.post('/visitor-requests/', data: request.toJson());
  }
}
