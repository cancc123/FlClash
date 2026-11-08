import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
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

ResponseBody _json(Object body, int status) {
  return ResponseBody.fromString(
    json.encode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

XboardClient _client({
  required Object body,
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

/// The panel's own plan shape: prices arrive in cents, computed in floating
/// point, so a year of ¥81.60 comes back as 8159.999999999999.
Map<String, Object?> _planJson({
  int id = 1,
  String name = '月付300G',
  int transferEnable = 300,
  num? month = 800,
  num? year = 8159.999999999999,
  num? onetime,
  num? reset = 800,
  int sell = 1,
  int renew = 1,
}) {
  return {
    'id': id,
    'name': name,
    'transfer_enable': transferEnable,
    'speed_limit': 1000,
    'device_limit': 10,
    'sell': sell,
    'renew': renew,
    'content': '## 套餐详情',
    'month_price': month,
    'quarter_price': null,
    'half_year_price': null,
    'year_price': year,
    'two_year_price': null,
    'three_year_price': null,
    'onetime_price': onetime,
    'reset_price': reset,
  };
}

void main() {
  group('XboardPlan', () {
    test('keeps every period the panel prices, in cents', () {
      final plan = XboardPlan.fromJson(_planJson());
      expect(plan.id, 1);
      expect(plan.transferEnableGb, 300);
      expect(plan.deviceLimit, 10);
      expect(plan.speedLimit, 1000);
      expect(plan.prices[XboardPeriod.monthly], 800);
      expect(plan.purchasePeriods, [XboardPeriod.monthly, XboardPeriod.yearly]);
      expect(plan.resetPrice, 800);
      expect(plan.canResetTraffic, isTrue);
    });

    test('a year of ¥81.60 rounds to 8160 cents, not 8159', () {
      final plan = XboardPlan.fromJson(_planJson());
      expect(plan.prices[XboardPeriod.yearly], 8160);
    });

    test('a one-time plan sells for a single period', () {
      final plan = XboardPlan.fromJson(
        _planJson(id: 3, name: '一元体验', month: null, year: null, onetime: 100, reset: null),
      );
      expect(plan.purchasePeriods, [XboardPeriod.onetime]);
      expect(plan.canResetTraffic, isFalse);
    });
  });

  test('a payment method adds the fee the panel configured', () {
    final method = XboardPaymentMethod.fromJson({
      'id': 3,
      'name': '微信',
      'payment': 'EPay',
      'handling_fee_fixed': 50,
      'handling_fee_percent': 2,
    });
    expect(method.feeOf(800), 66);
  });

  group('checkout', () {
    test('reads the gateway url EPay answers with', () {
      final checkout = XboardCheckout.fromJson({
        'type': 1,
        'data': 'https://epay.example.com/submit.php?money=8&sign=abc',
      });
      expect(checkout.isFree, isFalse);
      expect(checkout.data, startsWith('https://epay.example.com/submit.php'));
    });

    test('reads the amount the gateway will really charge', () {
      final checkout = XboardCheckout.fromJson({
        'type': 1,
        'data': 'https://pay.example.com/submit.php?money=1.02&sign=abc',
      });
      expect(checkout.amountCents, 102);
    });

    test('a url without money carries no amount', () {
      final checkout = XboardCheckout.fromJson({
        'type': 1,
        'data': 'https://pay.example.com/submit.php?sign=abc',
      });
      expect(checkout.amountCents, isNull);
    });

    test('a free order settles itself', () {
      final checkout = XboardCheckout.fromJson({'type': -1, 'data': true});
      expect(checkout.isFree, isTrue);
    });
  });

  group('XboardOrder', () {
    test('reads the panel status numbering', () {
      final pending = XboardOrder.fromJson({
        'trade_no': '202611081234',
        'status': 0,
        'total_amount': 800,
        'period': 'monthly',
        'created_at': 1794000000,
        'plan': {'id': 1, 'name': '月付300G'},
      });
      expect(pending.isPending, isTrue);
      expect(pending.isSettled, isFalse);
      expect(pending.planName, '月付300G');
      expect(pending.totalAmount, 800);
      expect(pending.createdAt, isNotNull);
    });

    test('completed and discounted both count as settled', () {
      for (final status in [1, 3, 4]) {
        expect(
          XboardOrder.fromJson({'trade_no': 'x', 'status': status}).isSettled,
          isTrue,
          reason: 'status $status',
        );
      }
      expect(
        XboardOrder.fromJson({'trade_no': 'x', 'status': 2}).isCancelled,
        isTrue,
      );
    });
  });

  group('client', () {
    test('lists the plans the panel sells', () async {
      final client = _client(
        body: {
          'status': 'success',
          'data': [_planJson(), _planJson(id: 9, sell: 0)],
        },
      );
      final plans = await client.plans();
      expect(plans, hasLength(1));
      expect(plans.single.id, 1);
    });

    test('orders answer a trade number', () async {
      RequestOptions? seen;
      final client = _client(
        body: {'status': 'success', 'data': '202611081234'},
        onRequest: (options) => seen = options,
      );
      final tradeNo = await client.createOrder(
        authData: 'Bearer abc',
        planId: 1,
        period: XboardPeriod.monthly,
        couponCode: 'SAVE',
      );
      expect(tradeNo, '202611081234');
      expect(seen?.uri.path, '/api/v1/user/order/save');
      final body = seen?.data is String
          ? jsonDecode(seen!.data as String)
          : seen?.data;
      expect(body, {
        'plan_id': 1,
        // The panel validates the legacy period names and converts them itself.
        'period': 'month_price',
        'coupon_code': 'SAVE',
      });
    });

    test('an unpaid order is reported with the panel message', () async {
      final client = _client(
        status: 400,
        body: {
          'status': 'fail',
          'message': 'You have an unpaid or pending order',
          'data': null,
        },
      );
      expect(
        () => client.createOrder(
          authData: 'Bearer x',
          planId: 1,
          period: XboardPeriod.monthly,
        ),
        throwsA(
          isA<XboardException>()
              .having((e) => e.failure, 'failure', XboardFailure.rejected)
              .having((e) => e.message, 'message', contains('unpaid')),
        ),
      );
    });

    test('checkout answers its payload without the panel envelope', () async {
      final client = _client(
        body: {
          'type': 1,
          'data': 'https://pay.loveccvv.sbs/submit.php?money=1&sign=abc',
        },
      );
      final checkout = await client.checkout(
        authData: 'Bearer x',
        tradeNo: '1',
        methodId: 3,
      );
      expect(checkout.type, 1);
      expect(checkout.data, startsWith('https://pay.loveccvv.sbs/submit.php'));
    });

    test('a free checkout answers the same way', () async {
      final client = _client(body: {'type': -1, 'data': true});
      final checkout = await client.checkout(
        authData: 'Bearer x',
        tradeNo: '1',
        methodId: 3,
      );
      expect(checkout.isFree, isTrue);
    });

    test('order status arrives as a bare number', () async {
      final client = _client(
        body: {'status': 'success', 'data': 3},
        onRequest: (options) => expect(options.uri.queryParameters, {
          'trade_no': '1',
        }),
      );
      expect(await client.orderStatus(authData: 'Bearer x', tradeNo: '1'), 3);
    });

    test('registration answers the same auth payload as signing in', () async {
      final client = _client(
        body: {
          'status': 'success',
          'data': {
            'token': '6e7088789e613e73fa41ab09b6eb072b',
            'auth_data': 'Bearer abc',
            'is_admin': false,
          },
        },
      );
      final signIn = await client.register(
        username: 'flclashtest',
        password: 'Flclash.2026',
      );
      expect(signIn.token, '6e7088789e613e73fa41ab09b6eb072b');
      expect(signIn.authData, 'Bearer abc');
    });
  });
}
