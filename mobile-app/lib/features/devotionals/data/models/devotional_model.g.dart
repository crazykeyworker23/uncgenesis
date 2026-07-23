// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devotional_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DevotionalModelImpl _$$DevotionalModelImplFromJson(
  Map<String, dynamic> json,
) => _$DevotionalModelImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  slug: json['slug'] as String,
  date: json['date'] as String,
  biblePassage: json['bible_passage'] as String,
  bibleText: json['bible_text'] as String,
  content: json['content'] as String,
  audioUrl: json['audio_url'] as String?,
  status: json['status'] as String,
  viewsCount: (json['views_count'] as num).toInt(),
);

Map<String, dynamic> _$$DevotionalModelImplToJson(
  _$DevotionalModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'date': instance.date,
  'bible_passage': instance.biblePassage,
  'bible_text': instance.bibleText,
  'content': instance.content,
  'audio_url': instance.audioUrl,
  'status': instance.status,
  'views_count': instance.viewsCount,
};
