import '../../data/models/requests_model.dart';

abstract class RequestsRepository {
  Future<void> submitPrayerRequest(PrayerRequestModel request);
  Future<void> submitVisitorRequest(VisitorRequestModel request);
}
