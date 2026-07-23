import 'package:dio/dio.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final Dio _dio;

  NotificationsRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<void> registerDeviceToken(String token, String deviceType) async {
    await _dio.post(
      '/notifications/devices/',
      data: {
        'token': token,
        'device_type': deviceType,
      },
    );
  }
}
