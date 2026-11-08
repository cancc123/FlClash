import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';

/// The panel FlClash signs in to. The subscription itself arrives on whatever
/// domain the panel reports, so this only names the one that answers the API.
const xboardHost = 'https://loveccvv.shop';

/// Asks the panel for the client format FlClash can read. Without it the panel
/// answers a shared `User-Agent` with a base64 list no Clash profile accepts.
///
/// The version is part of the flag: a panel gates Hysteria2 and newer protocol
/// settings behind a minimum client version, and reads a flag without one as a
/// client too old to carry them, which silently drops those nodes.
const _fallbackClientVersion = '1.0.0';

String get xboardClientFlag => 'flclash/${_clientVersion()}';

String _clientVersion() {
  try {
    final version = globalState.packageInfo.version.trim();
    return version.isEmpty ? _fallbackClientVersion : version;
  } catch (_) {
    return _fallbackClientVersion;
  }
}

enum XboardFailure {
  invalidCredentials,
  rateLimited,
  unauthorized,
  subscriptionUnavailable,
  invalidResponse,
  network,

  /// The panel refused the request and explained itself in `message`:
  /// an unpaid order, a disabled payment method, a sold-out plan.
  rejected,
}

class XboardException implements Exception {
  const XboardException(this.failure, {this.message});

  final XboardFailure failure;
  final String? message;

  @override
  String toString() =>
      'XboardException(${failure.name}${message == null ? '' : ', $message'})';
}

class XboardSubscription {
  const XboardSubscription({
    required this.subscribeUrl,
    this.planId,
    this.expireAt,
    this.upload = 0,
    this.download = 0,
    this.total = 0,
  });

  final String subscribeUrl;
  final int? planId;
  final DateTime? expireAt;
  final int upload;
  final int download;
  final int total;

  bool get isExpired {
    final expireAt = this.expireAt;
    return expireAt != null && expireAt.isBefore(DateTime.now());
  }

  bool get isExhausted => total > 0 && upload + download >= total;

  bool get isAvailable => !isExpired && !isExhausted;
}

typedef XboardSignIn = ({String token, String authData});

/// The panel's v1 JSON API: `passport/auth/login` hands back the subscription
/// token and a bearer, and `user/getSubscribe` answers the subscription url.
class XboardClient {
  XboardClient({Dio? dio, this.host = xboardHost}) : _dio = dio ?? request.dio;

  final Dio _dio;
  final String host;

  Future<XboardSignIn> signIn({
    required String username,
    required String password,
  }) async {
    final data = await _post('/api/v1/passport/auth/login', {
      'email': username,
      'password': password,
    });
    final token = data['token'];
    final authData = data['auth_data'];
    if (token is! String || authData is! String || token.isEmpty) {
      throw const XboardException(XboardFailure.invalidResponse);
    }
    return (token: token, authData: authData);
  }

  Future<XboardSubscription> subscription({required String authData}) async {
    final data = await _get('/api/v1/user/getSubscribe', authData: authData);
    final url = data['subscribe_url'];
    if (url is! String || url.isEmpty) {
      // A fresh account answers without a url: nothing has been bought yet.
      throw const XboardException(XboardFailure.subscriptionUnavailable);
    }
    final subscription = XboardSubscription(
      subscribeUrl: resolveSubscribeUrl(url, host: host),
      planId: _nullableCount(data['plan_id']),
      expireAt: _datetime(data['expired_at']),
      upload: _count(data['u']),
      download: _count(data['d']),
      total: _count(data['transfer_enable']),
    );
    if (!subscription.isAvailable) {
      throw const XboardException(XboardFailure.subscriptionUnavailable);
    }
    return subscription;
  }

  /// Rewrites a subscription url the panel built from a host no client can
  /// reach, and asks for the Clash format.
  static String resolveSubscribeUrl(
    String raw, {
    String host = xboardHost,
    String? clientFlag,
  }) {
    final flag = clientFlag ?? xboardClientFlag;
    final Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } on FormatException {
      throw const XboardException(XboardFailure.invalidResponse);
    }
    if (uri.host.isEmpty || _isUnreachableHost(uri.host)) {
      final fallback = Uri.parse(host);
      return fallback
          .replace(
            path: uri.path.isEmpty ? '/' : uri.path,
            queryParameters: {...uri.queryParameters, 'flag': flag},
          )
          .toString();
    }
    return uri
        .replace(
          queryParameters: {...uri.queryParameters, 'flag': flag},
        )
        .toString();
  }

  /// The url a stored token alone can rebuild, for a bearer that has expired.
  static String subscribeUrlForToken(
    String token, {
    String host = xboardHost,
    String? clientFlag,
  }) {
    return resolveSubscribeUrl(
      '$host/s/$token',
      host: host,
      clientFlag: clientFlag,
    );
  }

  static bool _isUnreachableHost(String host) {
    final host0 = host.toLowerCase();
    if (host0 == 'localhost' ||
        host0 == '::1' ||
        host0 == '[::1]' ||
        host0 == '0.0.0.0' ||
        host0 == '127.0.0.1') {
      return true;
    }
    final parts = host0.split('.');
    if (parts.length != 4) {
      return false;
    }
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) {
      return false;
    }
    if (first == 10 || first == 127) {
      return true;
    }
    if (first == 192 && second == 168) {
      return true;
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return true;
    }
    return false;
  }

  /// Registers a username on the panel and signs in with it, the same way
  /// [signIn] does: the panel answers a fresh token and bearer.
  Future<XboardSignIn> register({
    required String username,
    required String password,
  }) async {
    final data = await _requestData(
      path: '/api/v1/passport/auth/register',
      method: 'POST',
      body: {'email': username, 'password': password},
    );
    return _signInOf(data);
  }

  Future<List<XboardPlan>> plans() async {
    final data = await _requestData(
      path: '/api/v1/guest/plan/fetch',
      method: 'GET',
    );
    return [
      for (final item in _listOf(data))
        if (item['sell'] != 0 && item['sell'] != false)
          XboardPlan.fromJson(item),
    ];
  }

  Future<List<XboardPaymentMethod>> paymentMethods({
    required String authData,
  }) async {
    final data = await _requestData(
      path: '/api/v1/user/order/getPaymentMethod',
      method: 'GET',
      authData: authData,
      badRequest: XboardFailure.rejected,
    );
    return [for (final item in _listOf(data)) XboardPaymentMethod.fromJson(item)];
  }

  /// Opens an order and answers its trade number. The panel refuses a second
  /// order while one is unpaid, with a message naming that state.
  Future<String> createOrder({
    required String authData,
    required int planId,
    required XboardPeriod period,
    String? couponCode,
  }) async {
    final coupon = couponCode?.trim() ?? '';
    final data = await _requestData(
      path: '/api/v1/user/order/save',
      method: 'POST',
      authData: authData,
      badRequest: XboardFailure.rejected,
      body: {
        'plan_id': planId,
        'period': period.priceKey,
        if (coupon.isNotEmpty) 'coupon_code': coupon,
      },
    );
    if (data is String && data.isNotEmpty) {
      return data;
    }
    throw const XboardException(XboardFailure.invalidResponse);
  }

  Future<XboardCheckout> checkout({
    required String authData,
    required String tradeNo,
    required int methodId,
  }) async {
    // This one answers the payload itself (`type` and `data`) rather than the
    // panel's usual envelope.
    final data = await _requestData(
      path: '/api/v1/user/order/checkout',
      method: 'POST',
      authData: authData,
      badRequest: XboardFailure.rejected,
      enveloped: false,
      body: {'trade_no': tradeNo, 'method': methodId},
    );
    return XboardCheckout.fromJson(_mapOf(data));
  }

  /// 0 pending, 1 opening, 2 cancelled, 3 completed, 4 discounted.
  Future<int> orderStatus({
    required String authData,
    required String tradeNo,
  }) async {
    final data = await _requestData(
      path: '/api/v1/user/order/check',
      method: 'GET',
      authData: authData,
      badRequest: XboardFailure.rejected,
      query: {'trade_no': tradeNo},
    );
    if (data is num) {
      return data.toInt();
    }
    return int.tryParse('$data') ?? -1;
  }

  Future<List<XboardOrder>> pendingOrders({required String authData}) async {
    final data = await _requestData(
      path: '/api/v1/user/order/fetch',
      method: 'GET',
      authData: authData,
      badRequest: XboardFailure.rejected,
      query: {'status': 0},
    );
    return [for (final item in _listOf(data)) XboardOrder.fromJson(item)];
  }

  Future<void> cancelOrder({
    required String authData,
    required String tradeNo,
  }) async {
    await _requestData(
      path: '/api/v1/user/order/cancel',
      method: 'POST',
      authData: authData,
      badRequest: XboardFailure.rejected,
      body: {'trade_no': tradeNo},
    );
  }

  XboardSignIn _signInOf(Object? data) {
    final map = _mapOf(data);
    final token = map['token'];
    final authData = map['auth_data'];
    if (token is! String || authData is! String || token.isEmpty) {
      throw const XboardException(XboardFailure.invalidResponse);
    }
    return (token: token, authData: authData);
  }

  Future<Map<String, Object?>> _get(
    String path, {
    required String authData,
  }) async {
    return _mapOf(
      await _requestData(path: path, method: 'GET', authData: authData),
    );
  }

  Future<Map<String, Object?>> _post(String path, Object body) async {
    return _mapOf(
      await _requestData(path: path, method: 'POST', body: body),
    );
  }

  /// The `data` member of the panel's envelope, whatever shape it takes: an
  /// object, a list, a trade number or a status.
  Future<Object?> _requestData({
    required String path,
    required String method,
    Object? body,
    String? authData,
    Map<String, Object?>? query,
    XboardFailure badRequest = XboardFailure.invalidCredentials,
    bool enveloped = true,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        '$host$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          responseType: ResponseType.json,
          contentType: body == null ? null : Headers.jsonContentType,
          validateStatus: (_) => true,
          headers: {
            Headers.acceptHeader: Headers.jsonContentType,
            if (authData != null && authData.isNotEmpty)
              HttpHeaders.authorizationHeader: authData,
          },
        ),
      );
    } on DioException catch (error) {
      throw XboardException(
        XboardFailure.network,
        message: compactError(error),
      );
    }
    return _readData(
      response,
      badRequest: badRequest,
      enveloped: enveloped,
    );
  }

  Object? _readData(
    Response<Object?> response, {
    required XboardFailure badRequest,
    required bool enveloped,
  }) {
    final status = response.statusCode ?? 0;
    final body = _bodyOf(response.data);
    final message = body['message'];
    if (status >= 200 && status < 300) {
      if (!enveloped) {
        return body;
      }
      if (body['status'] == 'success') {
        return body['data'];
      }
    }
    throw switch (status) {
      400 || 422 => XboardException(
        badRequest,
        message: _validationMessage(body) ?? (message is String ? message : null),
      ),
      401 || 403 => XboardException(
        XboardFailure.unauthorized,
        message: message is String ? message : null,
      ),
      429 => XboardException(
        XboardFailure.rateLimited,
        message: message is String ? message : null,
      ),
      _ => XboardException(
        XboardFailure.invalidResponse,
        message: message is String ? message : 'HTTP $status',
      ),
    };
  }

  /// Laravel answers a validation failure with `errors` and no `message` the
  /// panel wrote, so the first field error stands in for it.
  String? _validationMessage(Map<String, Object?> body) {
    final errors = body['errors'];
    if (errors is! Map) {
      return null;
    }
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
    }
    return null;
  }

  Map<String, Object?> _mapOf(Object? data) {
    return data is Map ? data.cast<String, Object?>() : const {};
  }

  List<Map<String, Object?>> _listOf(Object? data) {
    if (data is! List) {
      return const [];
    }
    return [
      for (final item in data)
        if (item is Map) item.cast<String, Object?>(),
    ];
  }

  Map<String, Object?> _bodyOf(Object? data) {
    if (data is Map) {
      return data.cast<String, Object?>();
    }
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.cast<String, Object?>();
        }
      } on FormatException {
        return const {};
      }
    }
    return const {};
  }

  static int? _nullableCount(Object? value) {
    final parsed = _count(value);
    return parsed > 0 ? parsed : null;
  }

  static int _count(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static DateTime? _datetime(Object? value) {
    final seconds = _count(value);
    if (seconds <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}
