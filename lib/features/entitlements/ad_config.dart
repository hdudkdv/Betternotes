import 'package:flutter/foundation.dart';

/// AdMob identifiers and the platforms rewarded ads are available on.
///
/// iOS is intentionally excluded until an iOS app is registered in AdMob: the
/// iOS SDK aborts when it is initialized without `GADApplicationIdentifier` in
/// `Info.plist`.
abstract final class AdConfig {
  /// Android application ID, mirrored in `AndroidManifest.xml`.
  static const androidAppId = 'ca-app-pub-1753845428125059~9465582582';

  static const _androidRewardedUnitId =
      'ca-app-pub-1753845428125059/2237563329';

  /// Google's always-fillable unit, used for debug builds so live inventory and
  /// metrics stay clean.
  static const _androidRewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Debug and profile builds request test ads; release builds request live ads.
  static bool get useTestAds => !kReleaseMode;

  static String? get rewardedUnitId {
    if (!isSupported) return null;
    return useTestAds ? _androidRewardedTestUnitId : _androidRewardedUnitId;
  }
}
