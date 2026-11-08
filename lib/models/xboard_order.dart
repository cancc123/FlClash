/// The purchase periods the panel sells, in its own vocabulary. The legacy
/// key names the plan object carries the price under.
enum XboardPeriod {
  monthly('monthly', 'month_price'),
  quarterly('quarterly', 'quarter_price'),
  halfYearly('half_yearly', 'half_year_price'),
  yearly('yearly', 'year_price'),
  twoYearly('two_yearly', 'two_year_price'),
  threeYearly('three_yearly', 'three_year_price'),
  onetime('onetime', 'onetime_price'),
  resetTraffic('reset_traffic', 'reset_price');

  const XboardPeriod(this.apiValue, this.priceKey);

  final String apiValue;
  final String priceKey;

  bool get isTrafficReset => this == XboardPeriod.resetTraffic;
}

/// A plan the panel offers, with the price of every period it sells.
class XboardPlan {
  const XboardPlan({
    required this.id,
    required this.name,
    required this.transferEnableGb,
    required this.content,
    required this.prices,
    this.speedLimit,
    this.deviceLimit,
    this.renew = false,
    this.sell = true,
  });

  final int id;
  final String name;
  final int transferEnableGb;
  final String content;
  final Map<XboardPeriod, int> prices;
  final int? speedLimit;
  final int? deviceLimit;
  final bool renew;
  final bool sell;

  /// What a plan is bought for, without the traffic reset that is not a sale.
  List<XboardPeriod> get purchasePeriods => [
    for (final period in XboardPeriod.values)
      if (!period.isTrafficReset && (prices[period] ?? 0) > 0) period,
  ];

  int? get resetPrice => prices[XboardPeriod.resetTraffic];

  bool get canResetTraffic => (resetPrice ?? 0) > 0;

  factory XboardPlan.fromJson(Map<String, Object?> json) {
    final prices = <XboardPeriod, int>{};
    for (final period in XboardPeriod.values) {
      final cents = _centsOf(json[period.priceKey]);
      if (cents > 0) {
        prices[period] = cents;
      }
    }
    return XboardPlan(
      id: _intOf(json['id']),
      name: json['name'] is String ? json['name']! as String : '',
      transferEnableGb: _intOf(json['transfer_enable']),
      content: json['content'] is String ? json['content']! as String : '',
      prices: prices,
      speedLimit: _nullableIntOf(json['speed_limit']),
      deviceLimit: _nullableIntOf(json['device_limit']),
      renew: _boolOf(json['renew']),
      sell: _boolOf(json['sell'], orElse: true),
    );
  }
}

/// One way to pay, as the panel advertises it. `icon` stays unused: the panel's
/// icons are remote urls a signed-out client cannot always reach.
class XboardPaymentMethod {
  const XboardPaymentMethod({
    required this.id,
    required this.name,
    required this.payment,
    this.handlingFeeFixed = 0,
    this.handlingFeePercent = 0,
  });

  final int id;
  final String name;
  final String payment;
  final int handlingFeeFixed;
  final double handlingFeePercent;

  /// The fee the panel adds on checkout, in cents, for an amount in cents.
  int feeOf(int amountCents) {
    final percent = (amountCents * handlingFeePercent / 100).round();
    return percent + handlingFeeFixed;
  }

  factory XboardPaymentMethod.fromJson(Map<String, Object?> json) {
    return XboardPaymentMethod(
      id: _intOf(json['id']),
      name: json['name'] is String ? json['name']! as String : '',
      payment: json['payment'] is String ? json['payment']! as String : '',
      handlingFeeFixed: _intOf(json['handling_fee_fixed']),
      handlingFeePercent: _doubleOf(json['handling_fee_percent']),
    );
  }
}

/// What the panel answers a checkout with: a link to its payment gateway
/// (`url`), or the free order the panel already opened (`free`).
class XboardCheckout {
  const XboardCheckout({
    required this.type,
    required this.data,
    this.amountCents,
  });

  /// -1 opens the order at once, 0 is a url, 1 is the same url as a code the
  /// client draws, 2 is a form the browser has to submit.
  final int type;
  final String data;

  /// What the gateway will actually charge, in cents, taken from its own url:
  /// risk control may round the price up by a few cents per payment.
  final int? amountCents;

  bool get isFree => type == -1;

  bool get needsForm => type == 2;

  factory XboardCheckout.fromJson(Map<String, Object?> json) {
    final data = json['data'] is String ? json['data']! as String : '';
    return XboardCheckout(
      type: _intOf(json['type'], orElse: -2),
      data: data,
      amountCents: _amountOf(data),
    );
  }

  static int? _amountOf(String url) {
    final uri = Uri.tryParse(url);
    final money = uri?.queryParameters['money'];
    if (money == null) {
      return null;
    }
    final value = double.tryParse(money);
    if (value == null || value <= 0) {
      return null;
    }
    return (value * 100).round();
  }
}

/// An order as the panel lists it. `status` is the panel's own numbering:
/// 0 pending, 1 opening, 2 cancelled, 3 completed, 4 discounted.
class XboardOrder {
  const XboardOrder({
    required this.tradeNo,
    required this.status,
    required this.totalAmount,
    this.period,
    this.planName,
    this.createdAt,
  });

  final String tradeNo;
  final int status;
  final int totalAmount;
  final String? period;
  final String? planName;
  final DateTime? createdAt;

  bool get isPending => status == 0;

  bool get isSettled => status == 1 || status == 3 || status == 4;

  bool get isCancelled => status == 2;

  factory XboardOrder.fromJson(Map<String, Object?> json) {
    final plan = json['plan'];
    final createdAt = _intOf(json['created_at']);
    return XboardOrder(
      tradeNo: json['trade_no'] is String ? json['trade_no']! as String : '',
      status: _intOf(json['status']),
      totalAmount: _intOf(json['total_amount']),
      period: json['period'] is String ? json['period']! as String : null,
      planName: plan is Map && plan['name'] is String
          ? plan['name']! as String
          : null,
      createdAt: createdAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdAt * 1000)
          : null,
    );
  }
}

/// ¥ prices kept in cents. The panel multiplies by 100 in floating point, so a
/// stored 81.60 arrives as 8159.999999999999 and must round, not truncate.
int _centsOf(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return double.tryParse(value)?.round() ?? 0;
  }
  return 0;
}

int _intOf(Object? value, {int orElse = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? orElse;
  }
  if (value is bool) {
    return value ? 1 : 0;
  }
  return orElse;
}

int? _nullableIntOf(Object? value) {
  if (value == null) {
    return null;
  }
  final parsed = _intOf(value, orElse: -1);
  return parsed < 0 ? null : parsed;
}

double _doubleOf(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

bool _boolOf(Object? value, {bool orElse = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return orElse;
}
