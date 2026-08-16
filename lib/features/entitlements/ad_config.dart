import 'package:flutter/foundation.dart';

/// AdMob identifiers and the platforms rewarded ads are available on.
///
/// Live IDs are from the current AdMob account. Debug builds always request
/// Google's test rewarded units so metrics stay clean.
abstract final class AdConfig {
  /// Android application ID, mirrored in `AndroidManifest.xml`.
  static const androidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-5148114115565319~5749506300',
  );

  /// Android rewarded unit (`CoinsWerbung`).
  static const androidRewardedUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_UNIT_ID',
    defaultValue: 'ca-app-pub-5148114115565319/7963133920',
  );

  /// Coins granted after a completed rewarded ad. Matches AdMob's
  /// `CoinsWerbung` reward setting.
  static const coinsPerRewardedAd = 10;

  /// iOS application ID, mirrored in `Info.plist` `GADApplicationIdentifier`.
  static const iosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-5148114115565319~7652831090',
  );

  /// iOS rewarded unit from the current AdMob account.
  static const iosRewardedUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_UNIT_ID',
    defaultValue: 'ca-app-pub-5148114115565319/8291909166',
  );

  static const sampleAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const sampleIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const _androidRewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedTestUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get hasLiveAndroid => androidRewardedUnitId.isNotEmpty;
  static bool get hasLiveIos => iosRewardedUnitId.isNotEmpty;

  /// Debug/profile always use test ads. Release uses live units only when
  /// the matching platform ID has been configured.
  static bool get useTestAds {
    if (!kReleaseMode) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) return !hasLiveIos;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return !hasLiveAndroid;
    }
    return true;
  }

  static String? get rewardedUnitId {
    if (!isSupported) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return useTestAds ? _iosRewardedTestUnitId : iosRewardedUnitId;
    }
    return useTestAds ? _androidRewardedTestUnitId : androidRewardedUnitId;
  }
}
