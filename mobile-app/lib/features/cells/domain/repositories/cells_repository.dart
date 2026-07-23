import '../../data/models/cell_model.dart';

abstract class CellsRepository {
  Future<List<CellGroupModel>> getCells({
    required int page,
    String? searchQuery,
    String? meetingDay,
  });
  Future<CellGroupModel> getCellDetail(String slug);
}
