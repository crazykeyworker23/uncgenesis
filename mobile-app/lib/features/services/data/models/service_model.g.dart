// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceVerseModelImpl _$$ServiceVerseModelImplFromJson(
  Map<String, dynamic> json,
) => _$ServiceVerseModelImpl(
  id: (json['id'] as num).toInt(),
  book: json['book'] as String,
  chapter: (json['chapter'] as num).toInt(),
  verses: json['verses'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$$ServiceVerseModelImplToJson(
  _$ServiceVerseModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'book': instance.book,
  'chapter': instance.chapter,
  'verses': instance.verses,
  'text': instance.text,
};

_$ChurchServiceModelImpl _$$ChurchServiceModelImplFromJson(
  Map<String, dynamic> json,
) => _$ChurchServiceModelImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  slug: json['slug'] as String,
  date: json['date'] as String,
  videoUrl: json['video_url'] as String?,
  audioUrl: json['audio_url'] as String?,
  sermonNotes: json['sermon_notes'] as String?,
  viewsCount: (json['views_count'] as num).toInt(),
  isLive: json['is_live'] as bool,
  status: json['status'] as String,
  verses:
      (json['verses'] as List<dynamic>?)
          ?.map((e) => ServiceVerseModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$ChurchServiceModelImplToJson(
  _$ChurchServiceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'date': instance.date,
  'video_url': instance.videoUrl,
  'audio_url': instance.audioUrl,
  'sermon_notes': instance.sermonNotes,
  'views_count': instance.viewsCount,
  'is_live': instance.isLive,
  'status': instance.status,
  'verses': instance.verses,
};
