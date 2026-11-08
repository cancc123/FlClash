import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, Object?> body, int status) {
  return ResponseBody.fromString(
    json.encode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

XboardClient _client({
  required Map<String, Object?> body,
  int status = 200,
  void Function(RequestOptions options)? onRequest,
}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter((options) {
    onRequest?.call(options);
    return _json(body, status);
  });
  return XboardClient(dio: dio);
}

const _logInSuccess = {
  'status': 'success',
  'message': '操作成功',
  'data': {
    'token': '6e7088789e613e73fa41ab09b6eb072b',
    'auth_data': 'Bearer 10YcrlCgwa0FmteIxYBDawTbgWVYNOhVmg97MrU428f8682a',
    'is_admin': false,
  },
  'error': null,
};

Map<String, Object?> _subscribeSuccess({int expire = 1811864060}) => {
  'status': 'success',
  'message': '操作成功',
  'data': {
    'subscribe_url': 'https://xp.loveccvv.shop/s/6e7088789e613e73fa41ab09b6eb072b',
    'expired_at': expire,
    'u': 1856223824,
    'd': 20446111913,
    'transfer_enable': 322122547200,
  },
  'error': null,
};

void main() {
  group('signIn', () {
    test('reads the subscription token and the bearer', () async {
      final client = _client(body: _logInSuccess);
      final signIn = await client.signIn(
        username: 'can',
        password: 'secret',
      );
      expect(signIn.token, '6e7088789e613e73fa41ab09b6eb072b');
      expect(signIn.authData, startsWith('Bearer '));
    });

    test('sends the username in the email field the panel validates', () async {
      RequestOptions? seen;
      final client = _client(body: _logInSuccess, onRequest: (o) => seen = o);
      await client.signIn(username: 'can', password: 'secret');
      expect(seen?.uri.path, '/api/v1/passport/auth/login');
      expect(seen?.method, 'POST');
      final body = seen?.data;
      expect(
        body is String ? jsonDecode(body) : body,
        {'email': 'can', 'password': 'secret'},
      );
    });

    test('maps a rejected password to invalidCredentials', () async {
      final client = _client(
        status: 400,
        body: {
          'status': 'fail',
          'message': '邮箱或密码错误',
          'data': null,
          'error': null,
        },
      );
      expect(
        () => client.signIn(username: 'can', password: 'nope'),
        throwsA(
          isA<XboardException>().having(
            (error) => error.failure,
            'failure',
            XboardFailure.invalidCredentials,
          ),
        ),
      );
    });

    test('maps the password limit to rateLimited', () async {
      final client = _client(
        status: 429,
        body: {'status': 'fail', 'message': 'too many', 'data': null},
      );
      expect(
        () => client.signIn(username: 'can', password: 'nope'),
        throwsA(
          isA<XboardException>().having(
            (error) => error.failure,
            'failure',
            XboardFailure.rateLimited,
          ),
        ),
      );
    });
  });

  group('subscription', () {
    test('keeps the panel host and asks for the clash format', () async {
      final client = _client(body: _subscribeSuccess());
      final subscription = await client.subscription(authData: 'Bearer x');
      final uri = Uri.parse(subscription.subscribeUrl);
      expect(uri.host, 'xp.loveccvv.shop');
      expect(uri.path, '/s/6e7088789e613e73fa41ab09b6eb072b');
      expect(uri.queryParameters['flag'], startsWith('flclash/'),
          reason: '面板按 flag 里的版本决定是否下发 Hysteria2 等新协议节点');
      expect(subscription.upload, 1856223824);
      expect(subscription.total, 322122547200);
      expect(subscription.isAvailable, isTrue);
    });

    test('sends the bearer as the authorization header', () async {
      RequestOptions? seen;
      final client = _client(
        body: _subscribeSuccess(),
        onRequest: (o) => seen = o,
      );
      await client.subscription(authData: 'Bearer abc');
      expect(seen?.headers['Authorization'], 'Bearer abc');
      expect(seen?.uri.path, '/api/v1/user/getSubscribe');
    });

    test('maps a stale bearer to unauthorized', () async {
      final client = _client(
        status: 403,
        body: {
          'status': 'fail',
          'message': '未登录或登陆已过期',
          'data': null,
        },
      );
      expect(
        () => client.subscription(authData: 'Bearer stale'),
        throwsA(
          isA<XboardException>().having(
            (error) => error.failure,
            'failure',
            XboardFailure.unauthorized,
          ),
        ),
      );
    });

    test('refuses an expired plan before the import runs', () async {
      final client = _client(body: _subscribeSuccess(expire: 1600000000));
      expect(
        () => client.subscription(authData: 'Bearer x'),
        throwsA(
          isA<XboardException>().having(
            (error) => error.failure,
            'failure',
            XboardFailure.subscriptionUnavailable,
          ),
        ),
      );
    });
  });

  group('resolveSubscribeUrl', () {
    test('rewrites a loopback host to the panel', () {
      final url = XboardClient.resolveSubscribeUrl(
        'http://localhost:7001/s/abc',
      );
      final uri = Uri.parse(url);
      expect(uri.host, 'loveccvv.shop');
      expect(uri.scheme, 'https');
      expect(uri.path, '/s/abc');
      expect(uri.queryParameters['flag'], startsWith('flclash/'),
          reason: '面板按 flag 里的版本决定是否下发 Hysteria2 等新协议节点');
    });

    test('rewrites a private address', () {
      final uri = Uri.parse(
        XboardClient.resolveSubscribeUrl('http://192.168.10.13:7001/s/abc'),
      );
      expect(uri.host, 'loveccvv.shop');
      expect(uri.path, '/s/abc');
    });

    test('keeps the panel host it is given', () {
      final uri = Uri.parse(
        XboardClient.resolveSubscribeUrl(
          'https://xp.example.com/s/abc',
          host: 'https://panel.example.com',
        ),
      );
      expect(uri.host, 'xp.example.com');
      expect(uri.queryParameters['flag'], startsWith('flclash/'),
          reason: '面板按 flag 里的版本决定是否下发 Hysteria2 等新协议节点');
    });

    test('keeps existing query parameters', () {
      final uri = Uri.parse(
        XboardClient.resolveSubscribeUrl('https://xp.example.com/s/abc?x=1'),
      );
      expect(uri.queryParameters['x'], '1');
      expect(uri.queryParameters['flag'], startsWith('flclash/'),
          reason: '面板按 flag 里的版本决定是否下发 Hysteria2 等新协议节点');
    });

    test('rebuilds a url from the stored token alone', () {
      final uri = Uri.parse(XboardClient.subscribeUrlForToken('abc'));
      expect(uri.host, 'loveccvv.shop');
      expect(uri.path, '/s/abc');
      expect(uri.queryParameters['flag'], startsWith('flclash/'),
          reason: '面板按 flag 里的版本决定是否下发 Hysteria2 等新协议节点');
    });
  });

  test('a transport failure is reported as network', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((options) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    });
    final client = XboardClient(dio: dio);
    expect(
      () => client.signIn(username: 'can', password: 'secret'),
      throwsA(
        isA<XboardException>().having(
          (error) => error.failure,
          'failure',
          XboardFailure.network,
        ),
      ),
    );
  });
}
