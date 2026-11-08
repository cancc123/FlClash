// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../xboard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(xboardClient)
final xboardClientProvider = XboardClientProvider._();

final class XboardClientProvider
    extends $FunctionalProvider<XboardClient, XboardClient, XboardClient>
    with $Provider<XboardClient> {
  XboardClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'xboardClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$xboardClientHash();

  @$internal
  @override
  $ProviderElement<XboardClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  XboardClient create(Ref ref) {
    return xboardClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(XboardClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<XboardClient>(value),
    );
  }
}

String _$xboardClientHash() => r'be609dfbf75b9e641d3f1e9f97aa7cbc8204666c';

@ProviderFor(xboardAccount)
final xboardAccountProvider = XboardAccountProvider._();

final class XboardAccountProvider
    extends $FunctionalProvider<XboardAccount?, XboardAccount?, XboardAccount?>
    with $Provider<XboardAccount?> {
  XboardAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'xboardAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$xboardAccountHash();

  @$internal
  @override
  $ProviderElement<XboardAccount?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  XboardAccount? create(Ref ref) {
    return xboardAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(XboardAccount? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<XboardAccount?>(value),
    );
  }
}

String _$xboardAccountHash() => r'3309df6459363a0da193b1824bcb9d79034a5d6b';
