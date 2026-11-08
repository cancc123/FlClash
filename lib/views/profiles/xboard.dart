import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/profiles/xboard_auth.dart';
import 'package:fl_clash/views/profiles/xboard_plans.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showXboardAccountSheet(BuildContext context) {
  return showFormSheet<void>(
    context: context,
    builder: (_) => const XboardAccountForm(),
  );
}

/// The airport account this device is signed in with: what it bought, when it
/// expires, and the way to buy or renew more.
class XboardAccountForm extends ConsumerStatefulWidget {
  const XboardAccountForm({super.key});

  @override
  ConsumerState<XboardAccountForm> createState() => _XboardAccountFormState();
}

class _XboardAccountFormState extends ConsumerState<XboardAccountForm> {
  bool _saving = false;
  XboardFailure? _failure;
  String? _failureMessage;

  String? _errorText(AppLocalizations appLocalizations) {
    final failure = _failure;
    if (failure == null) {
      return null;
    }
    return switch (failure) {
      XboardFailure.network => appLocalizations.xboardNetworkError,
      XboardFailure.unauthorized => appLocalizations.xboardSessionExpired,
      XboardFailure.subscriptionUnavailable =>
        appLocalizations.xboardSubscriptionUnavailable,
      XboardFailure.rejected =>
        _failureMessage?.trim().isNotEmpty == true
            ? _failureMessage!.trim()
            : appLocalizations.xboardRequestRejected,
      _ => appLocalizations.xboardImportFailed,
    };
  }

  Future<void> _refresh() async {
    if (_saving) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    setState(() {
      _saving = true;
      _failure = null;
      _failureMessage = null;
    });
    try {
      await ref.read(xboardActionProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      dialogs.showBanner(appLocalizations.xboardRefreshSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        if (error is XboardException) {
          _failure = error.failure;
          _failureMessage = error.message;
        } else {
          _failure = XboardFailure.invalidResponse;
        }
      });
    }
  }

  void _openPlans() {
    final rootContext = rootNavigatorKey.currentContext;
    // The sheet's barrier stays over a page pushed from it and swallows every
    // tap, so the sheet closes first and the plans open on the next frame.
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootContext == null) {
        return;
      }
      unawaited(BaseNavigator.push<void>(rootContext, const XboardPlansView()));
    });
  }

  void _signOut() {
    ref.read(xboardActionProvider.notifier).signOut();
    Navigator.of(context).pop();
    // Signing out is not a dead end: the sign-in page is the way back in.
    unawaited(requestXboardSignIn());
  }

  Future<void> _signIn() async {
    Navigator.of(context).pop();
    final signedIn = await requestXboardSignIn();
    if (!signedIn) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final account = ref.watch(xboardAccountProvider);
    return FormPage(
      title: appLocalizations.xboardAccount,
      saveLabel: appLocalizations.xboardRefresh,
      onSave: () => unawaited(_refresh()),
      saving: _saving,
      error: _errorText(appLocalizations),
      children: [
        if (account == null)
          generateSection(
            items: [
              FormRow(
                title: appLocalizations.xboardSignIn,
                onPressed: _signIn,
              ),
            ],
          )
        else ...[
          generateSection(
            items: [
              FormRow(
                title: appLocalizations.username,
                trailing: Text(account.username),
              ),
              FormRow(
                title: appLocalizations.server,
                trailing: Text(Uri.parse(xboardHost).host),
              ),
              FormRow(
                title: appLocalizations.expireTime,
                trailing: Text(
                  account.expireAt?.show ?? appLocalizations.infiniteTime,
                ),
              ),
              if (account.total > 0)
                FormRow(
                  title: appLocalizations.traffic,
                  trailing: Text(
                    '${(account.upload + account.download).traffic.show}'
                    ' / ${account.total.traffic.show}',
                  ),
                ),
            ],
          ),
          generateSection(
            items: [
              FormRow(
                title: appLocalizations.xboardPlans,
                trailing: Text(
                  account.total > 0
                      ? appLocalizations.xboardBuyOrRenew
                      : appLocalizations.xboardNoSubscription,
                ),
                onPressed: _openPlans,
              ),
            ],
          ),
          generateSection(
            items: [
              FormRow(
                title: appLocalizations.xboardSignOut,
                onPressed: _signOut,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
