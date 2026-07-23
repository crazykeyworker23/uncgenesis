import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required int id,
    required String title,
    required String slug,
    required String description,
    @JsonKey(name: 'cover_image') String? coverImage,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    required String location,
    int? capacity,
    @JsonKey(name: 'requires_registration') required bool requiresRegistration,
    required String status,
    @JsonKey(name: 'registered_count') int? registeredCount,
    @JsonKey(name: 'is_registered') bool? isRegistered,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
