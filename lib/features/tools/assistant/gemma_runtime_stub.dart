import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemma_device_profile.dart';
import 'gemma_model_catalog.dart';

enum GemmaPhase { idle, checking, downloading, ready, failed }

final gemmaRuntimeProvider = ChangeNotifierProvider<GemmaRuntime>(
  (ref) => GemmaRuntime.instance,
);

class GemmaRuntime extends ChangeNotifier {
  GemmaRuntime._();

  static final GemmaRuntime instance = GemmaRuntime._();

  GemmaPhase phase = GemmaPhase.idle;
  double progress = 0;
  String? error;
  GemmaDeviceProfile? lastProfile;
  GemmaModelSpec? spec;

  bool get isSupported => false;
  bool get isReady => false;

  Future<void> restore() async {}

  Future<GemmaDeviceProfile> runCheck() async {
    phase = GemmaPhase.checking;
    error = null;
    notifyListeners();
    lastProfile = await GemmaDeviceProbe.measure();
    spec = GemmaModelCatalog.byTier(lastProfile!.recommended);
    phase = GemmaPhase.idle;
    notifyListeners();
    return lastProfile!;
  }

  Future<void> installRecommended() async {
    lastProfile ??= await runCheck();
    await installTier(lastProfile!.recommended);
  }

  Future<void> installTier(GemmaModelTier tier) async {
    spec = GemmaModelCatalog.byTier(tier);
    phase = GemmaPhase.failed;
    error = 'unsupported';
    notifyListeners();
  }

  Future<String?> complete(
    String user, {
    required bool german,
    String? extra,
  }) async {
    return null;
  }

  void resetConversation() {}
}
