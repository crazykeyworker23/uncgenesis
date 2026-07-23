import '../../data/models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ChurchServiceModel>> getServices({required int page});
  Future<ChurchServiceModel> getServiceDetail(String slug);
}
