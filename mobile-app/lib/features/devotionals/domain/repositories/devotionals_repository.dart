import '../../data/models/devotional_model.dart';

abstract class DevotionalsRepository {
  Future<List<DevotionalModel>> getDevotionals({
    required int page,
    String? searchQuery,
  });
  Future<DevotionalModel> getDevotionalDetail(String slug);
}
