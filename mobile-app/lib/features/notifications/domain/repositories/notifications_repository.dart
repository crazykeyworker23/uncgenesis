abstract class NotificationsRepository {
  Future<void> registerDeviceToken(String token, String deviceType);
}
