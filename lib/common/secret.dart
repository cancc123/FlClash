import 'dart:convert';
import 'dart:math';

const _secretFormatVersion = 'v1';
const _secretNonceLength = 16;
const _secretMask = <int>[
  0x9d,
  0x42,
  0xe7,
  0x1b,
  0x68,
  0xb4,
  0x35,
  0xca,
  0x7f,
  0x20,
  0xd1,
  0x56,
  0x83,
  0xfa,
  0x0c,
  0xa9,
];

/// Obfuscates a secret stored in the config JSON.
///
/// This only prevents accidental plain-text disclosure. It is deliberately not
/// a security boundary against reverse engineering or same-user access.
String encodeSecret(String secret) {
  if (secret.isEmpty) {
    return '';
  }
  final random = Random.secure();
  final nonce = List<int>.generate(
    _secretNonceLength,
    (_) => random.nextInt(256),
    growable: false,
  );
  final secretBytes = utf8.encode(secret);
  final obfuscated = List<int>.generate(
    secretBytes.length,
    (index) =>
        secretBytes[index] ^
        nonce[index % nonce.length] ^
        _secretMask[index % _secretMask.length],
    growable: false,
  );
  return [
    _secretFormatVersion,
    base64UrlEncode(nonce),
    base64UrlEncode(obfuscated),
  ].join('.');
}

String decodeSecret(String? value) {
  if (value == null || value.isEmpty) {
    return '';
  }
  final parts = value.split('.');
  if (parts.length != 3 || parts[0] != _secretFormatVersion) {
    return value;
  }
  try {
    final nonce = base64Url.decode(parts[1]);
    final obfuscated = base64Url.decode(parts[2]);
    if (nonce.length != _secretNonceLength) {
      return '';
    }
    final secretBytes = List<int>.generate(
      obfuscated.length,
      (index) =>
          obfuscated[index] ^
          nonce[index % nonce.length] ^
          _secretMask[index % _secretMask.length],
      growable: false,
    );
    return utf8.decode(secretBytes);
  } on FormatException {
    return '';
  }
}
