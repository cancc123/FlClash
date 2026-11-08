import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The gate the app opens behind the disclaimer: without an account on the
/// panel there is no subscription and nothing to show, so signing in or
/// registering is the only way in.
Future<bool> requestXboardSignIn() async {
  final context = rootNavigatorKey.currentContext;
  if (context == null) {
    return false;
  }
  final signedIn = await BaseNavigator.push<bool>(context, const XboardAuthPage());
  return signedIn == true;
}

class XboardAuthPage extends ConsumerStatefulWidget {
  const XboardAuthPage({super.key});

  @override
  ConsumerState<XboardAuthPage> createState() => _XboardAuthPageState();
}

class _XboardAuthPageState extends ConsumerState<XboardAuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmController = TextEditingController();
  final _confirmFocusNode = FocusNode();
  bool _isRegister = false;
  bool _saving = false;
  XboardFailure? _failure;
  String? _failureMessage;
  bool _missingUsername = false;
  bool _missingPassword = false;
  bool _missingConfirm = false;
  bool _passwordMismatch = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _confirmController.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _failure = null;
      _failureMessage = null;
      _missingUsername = false;
      _missingPassword = false;
      _missingConfirm = false;
      _passwordMismatch = false;
      _confirmController.clear();
    });
  }

  String? _errorText(AppLocalizations appLocalizations) {
    if (_missingUsername) {
      return appLocalizations.emptyTip(appLocalizations.username);
    }
    if (_missingPassword) {
      return appLocalizations.emptyTip(appLocalizations.password);
    }
    if (_missingConfirm) {
      return appLocalizations.emptyTip(appLocalizations.xboardConfirmPassword);
    }
    if (_passwordMismatch) {
      return appLocalizations.xboardPasswordMismatch;
    }
    final failure = _failure;
    if (failure == null) {
      return null;
    }
    return switch (failure) {
      XboardFailure.invalidCredentials =>
        appLocalizations.xboardInvalidCredentials,
      XboardFailure.rateLimited => appLocalizations.xboardRateLimited,
      XboardFailure.unauthorized => appLocalizations.xboardSessionExpired,
      XboardFailure.subscriptionUnavailable =>
        appLocalizations.xboardSubscriptionUnavailable,
      XboardFailure.network => appLocalizations.xboardNetworkError,
      XboardFailure.invalidResponse => appLocalizations.xboardInvalidResponse,
      XboardFailure.rejected =>
        _failureMessage?.trim().isNotEmpty == true
            ? _failureMessage!.trim()
            : appLocalizations.xboardRequestRejected,
    };
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final missingUsername = username.isEmpty;
    final missingPassword = password.isEmpty;
    final missingConfirm = _isRegister && _confirmController.text.isEmpty;
    final mismatch =
        _isRegister && _confirmController.text != password;
    if (missingUsername || missingPassword || missingConfirm || mismatch) {
      setState(() {
        _missingUsername = missingUsername;
        _missingPassword = missingPassword;
        _missingConfirm = missingConfirm;
        _passwordMismatch = mismatch;
      });
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
      _failureMessage = null;
      _missingUsername = false;
      _missingPassword = false;
      _missingConfirm = false;
      _passwordMismatch = false;
    });
    try {
      final action = ref.read(xboardActionProvider.notifier);
      if (_isRegister) {
        await action.register(username: username, password: password);
      } else {
        await action.signInAndImport(username: username, password: password);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return FormPage(
      title: appLocalizations.xboardAccount,
      saveLabel: _isRegister
          ? appLocalizations.xboardRegister
          : appLocalizations.xboardSignIn,
      onSave: () => unawaited(_submit()),
      saving: _saving,
      error: _errorText(appLocalizations),
      children: [
        generateSection(
          items: [
            FormRow(
              title: appLocalizations.username,
              invalid: _missingUsername,
              trailing: FormRowTextField(
                controller: _usernameController,
                autofocus: true,
                hintText: appLocalizations.required,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                inputFormatters: TextInputLimits.limit(TextInputLimits.name),
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
            ),
            FormRow(
              title: appLocalizations.password,
              invalid: _missingPassword,
              trailing: FormRowSecretTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hintText: appLocalizations.required,
                textInputAction: _isRegister
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_isRegister) {
                    _confirmFocusNode.requestFocus();
                  } else {
                    unawaited(_submit());
                  }
                },
              ),
            ),
            if (_isRegister)
              FormRow(
                title: appLocalizations.xboardConfirmPassword,
                invalid: _missingConfirm || _passwordMismatch,
                trailing: FormRowSecretTextField(
                  controller: _confirmController,
                  focusNode: _confirmFocusNode,
                  hintText: appLocalizations.required,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => unawaited(_submit()),
                ),
              ),
          ],
          footer: _isRegister
              ? appLocalizations.xboardRegisterTip
              : appLocalizations.xboardSignInTip,
        ),
        generateSection(
          items: [
            FormRow(
              title: _isRegister
                  ? appLocalizations.xboardHasAccount
                  : appLocalizations.xboardNoAccount,
              onPressed: _toggleMode,
            ),
          ],
        ),
      ],
    );
  }
}
