import 'package:fl_clash/common/secret.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a secret never lands in the config as plain text', () {
    const secret = 'xx023136';
    final encoded = encodeSecret(secret);
    expect(encoded, isNot(contains(secret)));
    expect(encoded, startsWith('v1.'));
    expect(decodeSecret(encoded), secret);
  });

  test('each encoding carries its own nonce', () {
    expect(encodeSecret('same'), isNot(encodeSecret('same')));
  });

  test('an empty secret encodes to an empty string', () {
    expect(encodeSecret(''), '');
    expect(decodeSecret(''), '');
    expect(decodeSecret(null), '');
  });

  test('a value without the format version is taken as itself', () {
    expect(decodeSecret('plain'), 'plain');
  });

  test('a value that is not this format is taken as itself', () {
    expect(decodeSecret('v1.abc'), 'v1.abc');
  });

  test('a truncated value decodes to nothing rather than throwing', () {
    expect(decodeSecret('v1.abc.def'), '');
    expect(decodeSecret('v1.***.def'), '');
  });
}
