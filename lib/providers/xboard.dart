import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/xboard.g.dart';

@Riverpod(keepAlive: true)
XboardClient xboardClient(Ref ref) => XboardClient();

@riverpod
XboardAccount? xboardAccount(Ref ref) => ref.watch(xboardSettingProvider);
