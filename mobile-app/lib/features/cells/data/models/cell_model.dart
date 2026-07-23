import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../auth/data/models/user_model.dart';

part 'cell_model.freezed.dart';
part 'cell_model.g.dart';

double? _toDoubleNullable(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

@freezed
class CellGroupModel with _$CellGroupModel {
  const factory CellGroupModel({
    required int id,
    required String name,
    required String slug,
    UserModel? leader,
    @JsonKey(name: 'meeting_day') required String meetingDay,
    @JsonKey(name: 'meeting_time') required String meetingTime,
    required String address,
    @JsonKey(fromJson: _toDoubleNullable) double? latitude,
    @JsonKey(fromJson: _toDoubleNullable) double? longitude,
    String? description,
    required String status,
  }) = _CellGroupModel;

  factory CellGroupModel.fromJson(Map<String, dynamic> json) => _$CellGroupModelFromJson(json);
}
