import 'package:freezed_annotation/freezed_annotation.dart';

part 'requests_model.freezed.dart';
part 'requests_model.g.dart';

@freezed
class PrayerRequestModel with _$PrayerRequestModel {
  const factory PrayerRequestModel({
    @JsonKey(name: 'requester_name') required String requesterName,
    @JsonKey(name: 'requester_email') String? requesterEmail,
    @JsonKey(name: 'requester_phone') String? requesterPhone,
    required String subject,
    required String description,
    @JsonKey(name: 'is_anonymous') required bool isAnonymous,
  }) = _PrayerRequestModel;

  factory PrayerRequestModel.fromJson(Map<String, dynamic> json) => _$PrayerRequestModelFromJson(json);
}

@freezed
class VisitorRequestModel with _$VisitorRequestModel {
  const factory VisitorRequestModel({
    @JsonKey(name: 'full_name') required String fullName,
    String? email,
    String? phone,
    @JsonKey(name: 'age_range') required String ageRange,
    @JsonKey(name: 'how_did_you_find_us') required String howDidYouFindUs,
    required String message,
    @JsonKey(name: 'preferred_contact') required String preferredContact,
    @JsonKey(name: 'cell_group_id') int? cellGroupId,
  }) = _VisitorRequestModel;

  factory VisitorRequestModel.fromJson(Map<String, dynamic> json) => _$VisitorRequestModelFromJson(json);
}
