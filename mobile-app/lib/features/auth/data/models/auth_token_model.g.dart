// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthTokenModelImpl _$$AuthTokenModelImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokenModelImpl(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
    );

Map<String, dynamic> _$$AuthTokenModelImplToJson(
  _$AuthTokenModelImpl instance,
) => <String, dynamic>{
  'access': instance.accessToken,
  'refresh': instance.refreshToken,
};
