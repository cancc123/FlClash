// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../xboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_XboardAccount _$XboardAccountFromJson(Map<String, dynamic> json) =>
    _XboardAccount(
      username: json['username'] as String,
      password: json['password'] == null
          ? ''
          : decodeSecret(json['password'] as String?),
      authData: json['authData'] == null
          ? ''
          : decodeSecret(json['authData'] as String?),
      subscribeToken: json['subscribeToken'] as String? ?? '',
      profileId: (json['profileId'] as num?)?.toInt(),
      planId: (json['planId'] as num?)?.toInt(),
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
      expireAt: json['expireAt'] == null
          ? null
          : DateTime.parse(json['expireAt'] as String),
      upload: (json['upload'] as num?)?.toInt() ?? 0,
      download: (json['download'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$XboardAccountToJson(_XboardAccount instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': encodeSecret(instance.password),
      'authData': encodeSecret(instance.authData),
      'subscribeToken': instance.subscribeToken,
      'profileId': instance.profileId,
      'planId': instance.planId,
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'expireAt': instance.expireAt?.toIso8601String(),
      'upload': instance.upload,
      'download': instance.download,
      'total': instance.total,
    };
