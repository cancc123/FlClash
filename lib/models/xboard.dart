import 'package:fl_clash/common/secret.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/xboard.freezed.dart';
part 'generated/xboard.g.dart';

/// The xboard account FlClash signed in with, kept so the subscription can be
/// refreshed without asking for the password again.
@Freezed(toStringOverride: false)
abstract class XboardAccount with _$XboardAccount {
  const XboardAccount._();

  const factory XboardAccount({
    required String username,
    @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)
    @Default('')
    String password,
    @JsonKey(fromJson: decodeSecret, toJson: encodeSecret)
    @Default('')
    String authData,
    @Default('') String subscribeToken,
    int? profileId,
    int? planId,
    DateTime? lastSyncAt,
    DateTime? expireAt,
    @Default(0) int upload,
    @Default(0) int download,
    @Default(0) int total,
  }) = _XboardAccount;

  factory XboardAccount.fromJson(Map<String, Object?> json) =>
      _$XboardAccountFromJson(json);

  @override
  String toString() =>
      'XboardAccount(username: $username, password: ***, authData: ***, '
      'subscribeToken: $subscribeToken, profileId: $profileId, '
      'lastSyncAt: $lastSyncAt, expireAt: $expireAt)';
}
