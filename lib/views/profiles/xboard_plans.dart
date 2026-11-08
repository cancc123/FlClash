import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/profiles/xboard_checkout.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

String xboardPriceText(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

/// Opens the plans from anywhere that has a navigator under the app's root.
void openXboardPlans(BuildContext context) {
  unawaited(BaseNavigator.push<void>(context, const XboardPlansView()));
}

/// The plans the panel sells, with the period each one is bought for.
class XboardPlansView extends ConsumerStatefulWidget {
  const XboardPlansView({super.key});

  @override
  ConsumerState<XboardPlansView> createState() => _XboardPlansViewState();
}

class _XboardPlansViewState extends ConsumerState<XboardPlansView>
    with WidgetsBindingObserver {
  final _couponController = TextEditingController();
  final _periods = <int, XboardPeriod>{};
  List<XboardPlan>? _plans;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  XboardAction get _action => ref.read(xboardActionProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  /// The panel changes prices and plans between visits, so the page asks again
  /// whenever the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _action.plans();
      if (!mounted) {
        return;
      }
      setState(() {
        _plans = plans;
        _loading = false;
        for (final plan in plans) {
          _periods.putIfAbsent(plan.id, () => plan.purchasePeriods.first);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = _messageOf(error);
      });
    }
  }

  String _messageOf(Object error) {
    final appLocalizations = context.appLocalizations;
    if (error is! XboardException) {
      return appLocalizations.xboardPurchaseFailed;
    }
    return switch (error.failure) {
      XboardFailure.network => appLocalizations.xboardNetworkError,
      XboardFailure.unauthorized => appLocalizations.xboardSessionExpired,
      XboardFailure.rejected =>
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : appLocalizations.xboardPurchaseFailed,
      // Anything else is worth naming: the panel's answer is what makes a
      // failure diagnosable on a device nobody can attach a debugger to.
      _ => error.message?.trim().isNotEmpty == true
          ? '${appLocalizations.xboardPurchaseFailed}（${error.message!.trim()}）'
          : appLocalizations.xboardPurchaseFailed,
    };
  }

  Future<void> _purchase(XboardPlan plan, XboardPeriod period) async {
    if (_busy) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    setState(() => _busy = true);
    try {
      final pending = await _action.pendingOrders();
      if (pending.isNotEmpty && mounted) {
        final confirmed = await dialogs.showMessage(
          title: appLocalizations.xboardPendingOrderTitle,
          message: TextSpan(
            text: appLocalizations.xboardPendingOrderTip(
              xboardPriceText(pending.first.totalAmount),
            ),
          ),
          confirmText: appLocalizations.xboardCancelPendingOrder,
        );
        if (confirmed != true) {
          return;
        }
        await _action.cancelOrder(pending.first.tradeNo);
      }
      final purchase = await _action.purchase(
        plan: plan,
        period: period,
        couponCode: _couponController.text,
      );
      if (!mounted) {
        return;
      }
      if (purchase.checkout.isFree) {
        await _action.awaitPayment(purchase.tradeNo);
        if (!mounted) {
          return;
        }
        dialogs.showBanner(appLocalizations.xboardPurchaseSuccess);
        return;
      }
      await showXboardPaymentSheet(context, purchase: purchase);
    } catch (error) {
      if (!mounted) {
        return;
      }
      dialogs.showBanner(_messageOf(error), level: BannerLevel.error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final plans = _plans;
    return Scaffold(
      title: appLocalizations.xboardPlans,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.refresh,
          tooltip: appLocalizations.update,
          onPressed: _load,
        ),
      ],
      body: XboardRefreshList(
        // Only the first load takes the page over; a refresh keeps the list and
        // shows the hint above it.
        refreshing: _loading && _plans != null,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
            top: context.sectionsTopPadding,
            bottom: 20 + context.bottomInset,
          ),
        children: [
          if (_loading && _plans == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: ActivityIndicator()),
            )
          else if (_error case final error?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(error, textAlign: TextAlign.center),
            )
          else ...[
            if (plans != null && plans.isNotEmpty)
              generateSection(
                items: [
                  FormRow(
                    title: appLocalizations.xboardCoupon,
                    trailing: FormRowTextField(
                      controller: _couponController,
                      hintText: appLocalizations.optional,
                      autocorrect: false,
                      inputFormatters: TextInputLimits.limit(
                        TextInputLimits.name,
                      ),
                    ),
                  ),
                ],
              ),
            for (final plan in plans ?? const <XboardPlan>[])
              _PlanSection(
                plan: plan,
                period: _periods[plan.id] ?? plan.purchasePeriods.first,
                currentPlanId: ref.watch(
                  xboardAccountProvider.select((account) => account?.planId),
                ),
                busy: _busy,
                onPeriodChanged: (period) {
                  setState(() => _periods[plan.id] = period);
                },
                onPurchase: (period) => unawaited(_purchase(plan, period)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A list that asks its owner to reload when the user pulls it past a little,
/// and shows that it is reloading while it does.
///
/// `RefreshIndicator` belongs to Material, which this app does not import, so
/// the gesture is made here out of the scroll notifications the list already
/// sends.
class XboardRefreshList extends StatefulWidget {
  const XboardRefreshList({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshing = false,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  State<XboardRefreshList> createState() => _XboardRefreshListState();
}

class _XboardRefreshListState extends State<XboardRefreshList> {
  static const _trigger = 64.0;
  static const _maxHint = 72.0;

  double _pull = 0;

  bool _onScroll(ScrollNotification notification) {
    if (widget.refreshing) {
      return false;
    }
    if (notification is OverscrollNotification) {
      final overscroll = notification.overscroll;
      if (overscroll < 0 && notification.metrics.pixels <= 0) {
        _updatePull(_pull - overscroll);
      }
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < 0) {
        // A bouncing list moves past the edge instead of reporting overscroll.
        _updatePull(-pixels);
      }
      return false;
    }
    if (notification is ScrollEndNotification) {
      final shouldRefresh = _pull >= _trigger;
      if (_pull > 0) {
        setState(() => _pull = 0);
      }
      if (shouldRefresh) {
        unawaited(widget.onRefresh());
      }
    }
    return false;
  }

  void _updatePull(double value) {
    final next = value.clamp(0.0, _maxHint);
    if ((next - _pull).abs() < 0.5) {
      return;
    }
    setState(() => _pull = next);
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.refreshing ? _trigger : _pull;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: hint <= 0
              ? const SizedBox(width: double.infinity)
              : SizedBox(
                  height: hint,
                  child: Center(
                    child: widget.refreshing
                        ? const ActivityIndicator()
                        : GlyphIcon(
                            AppGlyphs.cloudSync,
                            size: 20,
                            color: context.colorScheme.primary.opacity60,
                          ),
                  ),
                ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// One plan and the period it is bought for.
class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.plan,
    required this.period,
    required this.currentPlanId,
    required this.busy,
    required this.onPeriodChanged,
    required this.onPurchase,
  });

  final XboardPlan plan;
  final XboardPeriod period;
  final int? currentPlanId;
  final bool busy;
  final ValueChanged<XboardPeriod> onPeriodChanged;
  final ValueChanged<XboardPeriod> onPurchase;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final price = plan.prices[period] ?? 0;
    final isCurrent = currentPlanId == plan.id;
    return Column(
      children: [
        generateSection(
          items: [
            FormRow(
              title: plan.name,
              trailing: Text(
                xboardPriceText(price),
                style: AppTextStyle.headline.of(context),
              ),
            ),
            FormRow(
              title: appLocalizations.traffic,
              trailing: Text('${plan.transferEnableGb} GB'),
            ),
            if (plan.speedLimit case final speed? when speed > 0)
              FormRow(
                title: appLocalizations.xboardSpeedLimit,
                trailing: Text('$speed Mbps'),
              ),
            if (plan.deviceLimit case final devices?)
              FormRow(
                title: appLocalizations.xboardDeviceLimit,
                trailing: Text('$devices'),
              ),
            if (plan.content.trim().isNotEmpty)
              FormRow(
                title: appLocalizations.xboardPlanDetail,
                trailing: Text(appLocalizations.xboardPlanDetailFold),
                onPressed: () => dialogs.showMessage(
                  title: plan.name,
                  message: TextSpan(text: plan.content),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (plan.purchasePeriods.length > 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in plan.purchasePeriods)
                      item == period
                          ? FilledButton(
                              onPressed: () => onPeriodChanged(item),
                              child: Text(_periodLabel(context, item)),
                            )
                          : OutlinedButton(
                              onPressed: () => onPeriodChanged(item),
                              child: Text(_periodLabel(context, item)),
                            ),
                  ],
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : () => onPurchase(period),
                child: Text(
                  isCurrent && plan.renew
                      ? appLocalizations.xboardRenew
                      : appLocalizations.xboardBuy,
                ),
              ),
              if (isCurrent && plan.canResetTraffic) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => onPurchase(XboardPeriod.resetTraffic),
                  child: Text(appLocalizations.xboardResetTraffic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _periodLabel(BuildContext context, XboardPeriod period) {
  final appLocalizations = context.appLocalizations;
  return switch (period) {
    XboardPeriod.monthly => appLocalizations.xboardPeriodMonthly,
    XboardPeriod.quarterly => appLocalizations.xboardPeriodQuarterly,
    XboardPeriod.halfYearly => appLocalizations.xboardPeriodHalfYearly,
    XboardPeriod.yearly => appLocalizations.xboardPeriodYearly,
    XboardPeriod.twoYearly => appLocalizations.xboardPeriodTwoYearly,
    XboardPeriod.threeYearly => appLocalizations.xboardPeriodThreeYearly,
    XboardPeriod.onetime => appLocalizations.xboardPeriodOnetime,
    XboardPeriod.resetTraffic => appLocalizations.xboardResetTraffic,
  };
}

Future<void> showXboardPaymentSheet(
  BuildContext context, {
  required XboardPurchase purchase,
}) {
  return showFormSheet<void>(
    context: context,
    builder: (_) => XboardPaymentSheet(purchase: purchase),
  );
}

/// The gateway the panel handed back, drawn as a code and offered to a browser,
/// while the order is polled until the panel settles it.
class XboardPaymentSheet extends ConsumerStatefulWidget {
  const XboardPaymentSheet({super.key, required this.purchase});

  final XboardPurchase purchase;

  @override
  ConsumerState<XboardPaymentSheet> createState() => _XboardPaymentSheetState();
}

class _XboardPaymentSheetState extends ConsumerState<XboardPaymentSheet> {
  bool _settled = false;
  bool _settling = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_watch());
  }

  Future<void> _watch() async {
    try {
      final status = await ref
          .read(xboardActionProvider.notifier)
          .awaitPayment(widget.purchase.tradeNo);
      if (!mounted) {
        return;
      }
      setState(() {
        _settling = false;
        _settled = status == 1 || status == 3 || status == 4;
        _error = _settled ? null : context.appLocalizations.xboardPaymentTimeout;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settling = false;
        _error = context.appLocalizations.xboardNetworkError;
      });
    }
  }

  Future<void> _openCheckout() async {
    await BaseNavigator.push<void>(
      context,
      XboardCheckoutPage(
        url: widget.purchase.checkout.data,
        title: context.appLocalizations.xboardPay,
      ),
    );
    if (!mounted || _settled) {
      return;
    }
    await _watch();
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.purchase.checkout.data);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _cancel() async {
    final appLocalizations = context.appLocalizations;
    try {
      await ref
          .read(xboardActionProvider.notifier)
          .cancelOrder(widget.purchase.tradeNo);
    } catch (error) {
      if (!mounted) {
        return;
      }
      dialogs.showBanner(
        appLocalizations.xboardCancelOrderFailed,
        level: BannerLevel.error,
      );
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return FormPage(
      title: appLocalizations.xboardPay,
      onSave: () {
        if (_settled) {
          Navigator.of(context).pop();
        } else {
          unawaited(_watch());
        }
      },
      saveLabel: _settled
          ? appLocalizations.confirm
          : appLocalizations.xboardCheckAgain,
      saving: _settling,
      error: _error,
      children: [
        generateSection(
          items: [
            FormRow(
              title: appLocalizations.xboardAmount,
              trailing: Text(
                xboardPriceText(
                  widget.purchase.checkout.amountCents ??
                      widget.purchase.amountCents,
                ),
              ),
            ),
            FormRow(
              title: appLocalizations.xboardPayMethod,
              trailing: Text(widget.purchase.method.name),
            ),
            FormRow(
              title: appLocalizations.xboardOrderNo,
              trailing: Text(widget.purchase.tradeNo),
            ),
          ],
        ),
        if (!_settled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Text(
                  appLocalizations.xboardPayTip,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.footnote.of(context).copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (xboardSupportsEmbeddedPay)
                  FilledButton(
                    onPressed: _openCheckout,
                    child: Text(appLocalizations.xboardPayNow),
                  )
                else
                  OutlinedButton(
                    onPressed: _openInBrowser,
                    child: Text(appLocalizations.xboardOpenInBrowser),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _settling ? null : _cancel,
                  child: Text(appLocalizations.xboardCancelOrder),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              appLocalizations.xboardPurchaseSuccess,
              textAlign: TextAlign.center,
              style: AppTextStyle.headline.of(context),
            ),
          ),
      ],
    );
  }
}
