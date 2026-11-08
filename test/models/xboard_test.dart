import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const account = XboardAccount(
    username: 'can',
    password: 'xx023136',
    authData: 'Bearer abc',
    subscribeToken: '6e7088789e613e73fa41ab09b6eb072b',
    profileId: 42,
    upload: 1856223824,
    download: 20446111913,
    total: 322122547200,
  );

  test('round-trips through the config json', () {
    final json = jsonEncode(account.toJson());
    expect(json, isNot(contains('xx023136')));
    expect(json, isNot(contains('Bearer abc')));

    final restored = XboardAccount.fromJson(
      jsonDecode(json) as Map<String, Object?>,
    );
    expect(restored.username, 'can');
    expect(restored.password, 'xx023136');
    expect(restored.authData, 'Bearer abc');
    expect(restored.subscribeToken, '6e7088789e613e73fa41ab09b6eb072b');
    expect(restored.profileId, 42);
    expect(restored.total, 322122547200);
  });

  test('a config written before the fields existed still reads', () {
    final account = XboardAccount.fromJson({'username': 'can'});
    expect(account.username, 'can');
    expect(account.password, '');
    expect(account.authData, '');
    expect(account.profileId, isNull);
  });

  test('toString keeps the secrets out of a log line', () {
    expect(account.toString(), isNot(contains('xx023136')));
    expect(account.toString(), isNot(contains('Bearer abc')));
  });

  test('an empty password writes nothing to decode', () {
    const empty = XboardAccount(username: 'can');
    expect(empty.toJson()['password'], '');
    expect(XboardAccount.fromJson(empty.toJson()).password, '');
  });
}
