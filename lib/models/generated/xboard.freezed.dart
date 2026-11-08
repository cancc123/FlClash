// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../xboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$XboardAccount {

 String get username;@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String get password;@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String get authData; String get subscribeToken; int? get profileId; int? get planId; DateTime? get lastSyncAt; DateTime? get expireAt; int get upload; int get download; int get total;
/// Create a copy of XboardAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XboardAccountCopyWith<XboardAccount> get copyWith => _$XboardAccountCopyWithImpl<XboardAccount>(this as XboardAccount, _$identity);

  /// Serializes this XboardAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as XboardAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XboardAccount&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.password, _this.password) || other.password == _this.password)&&(identical(other.authData, _this.authData) || other.authData == _this.authData)&&(identical(other.subscribeToken, _this.subscribeToken) || other.subscribeToken == _this.subscribeToken)&&(identical(other.profileId, _this.profileId) || other.profileId == _this.profileId)&&(identical(other.planId, _this.planId) || other.planId == _this.planId)&&(identical(other.lastSyncAt, _this.lastSyncAt) || other.lastSyncAt == _this.lastSyncAt)&&(identical(other.expireAt, _this.expireAt) || other.expireAt == _this.expireAt)&&(identical(other.upload, _this.upload) || other.upload == _this.upload)&&(identical(other.download, _this.download) || other.download == _this.download)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as XboardAccount;
  return Object.hash(runtimeType,_this.username,_this.password,_this.authData,_this.subscribeToken,_this.profileId,_this.planId,_this.lastSyncAt,_this.expireAt,_this.upload,_this.download,_this.total);
}



}

/// @nodoc
abstract mixin class $XboardAccountCopyWith<$Res>  {
  factory $XboardAccountCopyWith(XboardAccount value, $Res Function(XboardAccount) _then) = _$XboardAccountCopyWithImpl;
@useResult
$Res call({
 String username,@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String password,@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String authData, String subscribeToken, int? profileId, int? planId, DateTime? lastSyncAt, DateTime? expireAt, int upload, int download, int total
});




}
/// @nodoc
class _$XboardAccountCopyWithImpl<$Res>
    implements $XboardAccountCopyWith<$Res> {
  _$XboardAccountCopyWithImpl(this._self, this._then);

  final XboardAccount _self;
  final $Res Function(XboardAccount) _then;

/// Create a copy of XboardAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? password = null,Object? authData = null,Object? subscribeToken = null,Object? profileId = freezed,Object? planId = freezed,Object? lastSyncAt = freezed,Object? expireAt = freezed,Object? upload = null,Object? download = null,Object? total = null,}) {
  return _then(XboardAccount(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,authData: null == authData ? _self.authData : authData // ignore: cast_nullable_to_non_nullable
as String,subscribeToken: null == subscribeToken ? _self.subscribeToken : subscribeToken // ignore: cast_nullable_to_non_nullable
as String,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int?,planId: freezed == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [XboardAccount].
extension XboardAccountPatterns on XboardAccount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XboardAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XboardAccount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XboardAccount value)  $default,){
final _that = this;
switch (_that) {
case _XboardAccount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XboardAccount value)?  $default,){
final _that = this;
switch (_that) {
case _XboardAccount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String password, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String authData,  String subscribeToken,  int? profileId,  int? planId,  DateTime? lastSyncAt,  DateTime? expireAt,  int upload,  int download,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XboardAccount() when $default != null:
return $default(_that.username,_that.password,_that.authData,_that.subscribeToken,_that.profileId,_that.planId,_that.lastSyncAt,_that.expireAt,_that.upload,_that.download,_that.total);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String password, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String authData,  String subscribeToken,  int? profileId,  int? planId,  DateTime? lastSyncAt,  DateTime? expireAt,  int upload,  int download,  int total)  $default,) {final _that = this;
switch (_that) {
case _XboardAccount():
return $default(_that.username,_that.password,_that.authData,_that.subscribeToken,_that.profileId,_that.planId,_that.lastSyncAt,_that.expireAt,_that.upload,_that.download,_that.total);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String password, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)  String authData,  String subscribeToken,  int? profileId,  int? planId,  DateTime? lastSyncAt,  DateTime? expireAt,  int upload,  int download,  int total)?  $default,) {final _that = this;
switch (_that) {
case _XboardAccount() when $default != null:
return $default(_that.username,_that.password,_that.authData,_that.subscribeToken,_that.profileId,_that.planId,_that.lastSyncAt,_that.expireAt,_that.upload,_that.download,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _XboardAccount extends XboardAccount {
  const _XboardAccount({required this.username, @JsonKey(fromJson: decodeSecret, toJson: encodeSecret) this.password = '', @JsonKey(fromJson: decodeSecret, toJson: encodeSecret) this.authData = '', this.subscribeToken = '', this.profileId, this.planId, this.lastSyncAt, this.expireAt, this.upload = 0, this.download = 0, this.total = 0}): super._();
  factory _XboardAccount.fromJson(Map<String, dynamic> json) => _$XboardAccountFromJson(json);

@override final  String username;
@override@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) final  String password;
@override@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) final  String authData;
@override@JsonKey() final  String subscribeToken;
@override final  int? profileId;
@override final  int? planId;
@override final  DateTime? lastSyncAt;
@override final  DateTime? expireAt;
@override@JsonKey() final  int upload;
@override@JsonKey() final  int download;
@override@JsonKey() final  int total;

/// Create a copy of XboardAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XboardAccountCopyWith<_XboardAccount> get copyWith => __$XboardAccountCopyWithImpl<_XboardAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$XboardAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _XboardAccount&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.authData, authData) || other.authData == authData)&&(identical(other.subscribeToken, subscribeToken) || other.subscribeToken == subscribeToken)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt)&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,username,password,authData,subscribeToken,profileId,planId,lastSyncAt,expireAt,upload,download,total);
}



}

/// @nodoc
abstract mixin class _$XboardAccountCopyWith<$Res> implements $XboardAccountCopyWith<$Res> {
  factory _$XboardAccountCopyWith(_XboardAccount value, $Res Function(_XboardAccount) _then) = __$XboardAccountCopyWithImpl;
@override @useResult
$Res call({
 String username,@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String password,@JsonKey(fromJson: decodeSecret, toJson: encodeSecret) String authData, String subscribeToken, int? profileId, int? planId, DateTime? lastSyncAt, DateTime? expireAt, int upload, int download, int total
});




}
/// @nodoc
class __$XboardAccountCopyWithImpl<$Res>
    implements _$XboardAccountCopyWith<$Res> {
  __$XboardAccountCopyWithImpl(this._self, this._then);

  final _XboardAccount _self;
  final $Res Function(_XboardAccount) _then;

/// Create a copy of XboardAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? password = null,Object? authData = null,Object? subscribeToken = null,Object? profileId = freezed,Object? planId = freezed,Object? lastSyncAt = freezed,Object? expireAt = freezed,Object? upload = null,Object? download = null,Object? total = null,}) {
  return _then(_XboardAccount(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,authData: null == authData ? _self.authData : authData // ignore: cast_nullable_to_non_nullable
as String,subscribeToken: null == subscribeToken ? _self.subscribeToken : subscribeToken // ignore: cast_nullable_to_non_nullable
as String,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int?,planId: freezed == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
