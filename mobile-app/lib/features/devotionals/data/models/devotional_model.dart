import 'package:freezed_annotation/freezed_annotation.dart';

part 'devotional_model.freezed.dart';
part 'devotional_model.g.dart';

@freezed
class DevotionalModel with _$DevotionalModel {
  const factory DevotionalModel({
    required int id,
    required String title,
    required String slug,
    required String date,
    @JsonKey(name: 'bible_passage') required String biblePassage,
    @JsonKey(name: 'bible_text') required String bibleText,
    required String content,
    @JsonKey(name: 'audio_url') String? audioUrl,
    required String status,
    @JsonKey(name: 'views_count') required int viewsCount,
  }) = _DevotionalModel;

  factory DevotionalModel.fromJson(Map<String, dynamic> json) => _$DevotionalModelFromJson(json);
}
