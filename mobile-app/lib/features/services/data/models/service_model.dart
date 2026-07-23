import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

@freezed
class ServiceVerseModel with _$ServiceVerseModel {
  const factory ServiceVerseModel({
    required int id,
    required String book,
    required int chapter,
    required String verses,
    required String text,
  }) = _ServiceVerseModel;

  factory ServiceVerseModel.fromJson(Map<String, dynamic> json) => _$ServiceVerseModelFromJson(json);
}

@freezed
class ChurchServiceModel with _$ChurchServiceModel {
  const factory ChurchServiceModel({
    required int id,
    required String title,
    required String slug,
    required String date,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'sermon_notes') String? sermonNotes,
    @JsonKey(name: 'views_count') required int viewsCount,
    @JsonKey(name: 'is_live') required bool isLive,
    required String status,
    @Default([]) List<ServiceVerseModel> verses,
  }) = _ChurchServiceModel;

  factory ChurchServiceModel.fromJson(Map<String, dynamic> json) => _$ChurchServiceModelFromJson(json);
}
