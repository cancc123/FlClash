part of '../action.dart';

/// What a checkout handed back and what the caller polls.
typedef XboardPurchase = ({
  String tradeNo,
  XboardCheckout checkout,
  XboardPaymentMethod method,
  int amountCents,
});

@Riverpod(keepAlive: true)
class XboardAction extends _$XboardAction {
  static const _pollInterval = Duration(seconds: 3);
  static const _pollTimeout = Duration(minutes: 5);
  static const _syncMaxAge = Duration(minutes: 5);

  XboardClient get _client {
    return ref.read(xboardClientProvider);
  }

  XboardAccount? get _account => ref.read(xboardSettingProvider);

  @override
  void build() {}

  XboardAccount? get account => _account;

  /// Signs in and adopts the account: the subscription is imported when the
  /// panel has one to give, and left for a purchase to bring when it has not.
  Future<XboardAccount> signInAndImport({
    required String username,
    required String password,
  }) async {
    final signIn = await _client.signIn(
      username: username,
      password: password,
    );
    return _adopt(username: username, password: password, signIn: signIn);
  }

  Future<XboardAccount> register({
    required String username,
    required String password,
  }) async {
    final signIn = await _client.register(
      username: username,
      password: password,
    );
    return _adopt(username: username, password: password, signIn: signIn);
  }

  Future<XboardAccount> _adopt({
    required String username,
    required String password,
    required XboardSignIn signIn,
  }) async {
    final subscription = await _subscriptionOrNull(
      authData: signIn.authData,
      token: signIn.token,
    );
    final account = await _store(
      username: username,
      password: password,
      authData: signIn.authData,
      token: signIn.token,
      subscription: subscription,
    );
    if (subscription != null &&
        (subscription.planId ?? 0) > 0 &&
        account.profileId == null) {
      // The account is saved, so a later refresh can try again, but the caller
      // must not report a subscription the device does not have.
      throw const XboardException(XboardFailure.invalidResponse);
    }
    return account;
  }

  /// Re-reads the subscription, signing in again when the bearer has expired.
  /// [silent] keeps a background sync from raising a banner.
  Future<XboardAccount> refresh({bool silent = false}) async {
    final account = _account;
    if (account == null) {
      throw const XboardException(XboardFailure.unauthorized);
    }
    var authData = account.authData;
    var token = account.subscribeToken;
    XboardSubscription? subscription;
    try {
      subscription = await _subscriptionOrNull(
        authData: authData,
        token: token,
      );
    } on XboardException catch (error) {
      if (error.failure == XboardFailure.network) {
        rethrow;
      }
      if (account.password.isEmpty) {
        rethrow;
      }
      final signIn = await _client.signIn(
        username: account.username,
        password: account.password,
      );
      authData = signIn.authData;
      token = signIn.token;
      subscription = await _subscriptionOrNull(
        authData: authData,
        token: token,
      );
    }
    return _store(
      username: account.username,
      password: account.password,
      authData: authData,
      token: token,
      subscription: subscription,
      current: account,
    );
  }

  /// The cloud stays the only source of truth: the app asks the panel for the
  /// subscription whenever it starts, comes back to the foreground, or has been
  /// holding a stale copy for a while.
  Future<void> sync({bool force = false}) async {
    final account = _account;
    if (account == null || account.subscribeToken.isEmpty) {
      return;
    }
    if (!force) {
      final lastSyncAt = account.lastSyncAt;
      if (lastSyncAt != null &&
          DateTime.now().difference(lastSyncAt) < _syncMaxAge) {
        return;
      }
    }
    try {
      await refresh(silent: true);
    } catch (error) {
      commonPrint.log(
        'xboard sync failed ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<List<XboardPlan>> plans() {
    return _client.plans();
  }

  Future<List<XboardOrder>> pendingOrders() async {
    final account = _account;
    if (account == null) {
      return const [];
    }
    return _client.pendingOrders(authData: account.authData);
  }

  Future<void> cancelOrder(String tradeNo) async {
    final account = _account;
    if (account == null) {
      return;
    }
    await _client.cancelOrder(authData: account.authData, tradeNo: tradeNo);
  }

  /// Opens an order and asks the panel how to pay it. The caller shows the
  /// payment payload and then polls [orderStatus].
  Future<XboardPurchase> purchase({
    required XboardPlan plan,
    required XboardPeriod period,
    String? couponCode,
  }) async {
    final account = _account;
    if (account == null) {
      throw const XboardException(XboardFailure.unauthorized);
    }
    final tradeNo = await _client.createOrder(
      authData: account.authData,
      planId: plan.id,
      period: period,
      couponCode: couponCode,
    );
    final methods = await _client.paymentMethods(authData: account.authData);
    if (methods.isEmpty) {
      throw const XboardException(XboardFailure.rejected);
    }
    final method = methods.first;
    final checkout = await _client.checkout(
      authData: account.authData,
      tradeNo: tradeNo,
      methodId: method.id,
    );
    final amount =
        (plan.prices[period] ?? 0) + method.feeOf(plan.prices[period] ?? 0);
    return (
      tradeNo: tradeNo,
      checkout: checkout,
      method: method,
      amountCents: amount,
    );
  }

  Future<int> orderStatus(String tradeNo) async {
    final account = _account;
    if (account == null) {
      throw const XboardException(XboardFailure.unauthorized);
    }
    return _client.orderStatus(authData: account.authData, tradeNo: tradeNo);
  }

  /// Polls until the panel settles the order or the window closes, then brings
  /// the subscription the purchase bought. Returns the last status seen.
  Future<int> awaitPayment(String tradeNo) async {
    final deadline = DateTime.now().add(_pollTimeout);
    var status = 0;
    while (DateTime.now().isBefore(deadline)) {
      status = await orderStatus(tradeNo);
      if (status != 0) {
        break;
      }
      await Future<void>.delayed(_pollInterval);
    }
    if (status == 1 || status == 3 || status == 4) {
      await refresh();
      await _switchToAccountProfile();
    }
    return status;
  }

  void signOut() {
    ref.read(xboardSettingProvider.notifier).value = null;
  }

  XboardSubscription? _mockSubscriptionForTest;

  @visibleForTesting
  set subscriptionForTest(XboardSubscription? value) =>
      _mockSubscriptionForTest = value;

  Future<XboardSubscription?> _subscriptionOrNull({
    required String authData,
    required String token,
  }) async {
    if (_mockSubscriptionForTest != null) {
      return _mockSubscriptionForTest;
    }
    try {
      return await _client.subscription(authData: authData);
    } on XboardException catch (error) {
      // A bearer the panel dropped still leaves the subscribe url buildable.
      if (error.failure == XboardFailure.unauthorized && token.isNotEmpty) {
        return XboardSubscription(
          subscribeUrl: XboardClient.subscribeUrlForToken(token),
        );
      }
      // An account with no plan yet: nothing to import, not a failure.
      if (error.failure == XboardFailure.subscriptionUnavailable) {
        return null;
      }
      rethrow;
    }
  }

  Future<XboardAccount> _store({
    required String username,
    required String password,
    required String authData,
    required String token,
    required XboardSubscription? subscription,
    XboardAccount? current,
  }) async {
    final previous = current ?? _account;
    var profileId = previous?.profileId;
    final hasPlan = subscription != null && (subscription.planId ?? 0) > 0;
    if (hasPlan) {
      try {
        final profile = await _import(
          url: subscription.subscribeUrl,
          label: username,
          reuseProfileId: profileId,
        );
        profileId = profile.id;
      } catch (error) {
        commonPrint.log(
          'xboard import failed ${compactError(error)}',
          logLevel: LogLevel.warning,
        );
      }
    }
    final account = XboardAccount(
      username: username,
      password: password,
      authData: authData,
      subscribeToken: token,
      profileId: profileId,
      planId: subscription?.planId ?? previous?.planId,
      lastSyncAt: DateTime.now(),
      expireAt: subscription?.expireAt ?? previous?.expireAt,
      upload: subscription?.upload ?? previous?.upload ?? 0,
      download: subscription?.download ?? previous?.download ?? 0,
      total: subscription?.total ?? previous?.total ?? 0,
    );
    ref.read(xboardSettingProvider.notifier).value = account;
    if (hasPlan) {
      await _switchToAccountProfile();
    }
    return account;
  }

  Future<void> _switchToAccountProfile() async {
    final profileId = _account?.profileId;
    if (profileId == null) {
      return;
    }
    if (ref.read(profilesProvider).getProfile(profileId) == null) {
      return;
    }
    if (ref.read(currentProfileIdProvider) == profileId) {
      return;
    }
    ref.read(currentProfileIdProvider.notifier).value = profileId;
  }

  Future<Profile> _import({
    required String url,
    required String label,
    int? reuseProfileId,
  }) async {
    final profiles = ref.read(profilesProvider);
    // Signing in again after signing out has no profile id to hand back, and
    // the same subscription must not appear twice.
    final reused = reuseProfileId == null
        ? profiles.where((profile) => profile.url == url).firstOrNull
        : profiles.getProfile(reuseProfileId);
    final base = reused == null
        ? Profile.normal(url: url, label: label)
        : reused.copyWith(url: url);
    late final Profile updated;
    try {
      updated = await base.update(
        validate: (path, key) =>
            ref.read(coreHandlerProvider).validateProfile(path, key),
      );
    } on Object catch (error) {
      // Signing in runs before the core is up, and a core that is not running
      // cannot vet the file; the download itself is still worth keeping.
      commonPrint.log(
        'xboard validate failed ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      updated = await base.update(validate: (_, _) async => null);
    }
    final profile = ref.read(profilesProvider).optimizeLabel(updated);
    ref.read(profilesProvider.notifier).put(profile);
    final currentProfileId = ref.read(currentProfileIdProvider);
    if (currentProfileId == null) {
      ref.read(currentProfileIdProvider.notifier).value = profile.id;
    } else if (currentProfileId == profile.id) {
      ref.read(setupActionProvider.notifier).applyProfileDebounce(silence: true);
    }
    return profile;
  }
}
