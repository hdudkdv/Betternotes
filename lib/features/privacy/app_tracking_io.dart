import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

import '../entitlements/rewarded_ad_service.dart';

/// Shows the ATT dialog on a fresh iOS install, then starts ads.
///
/// Apple rejects the binary if ATT is linked but the prompt never appears
/// (Guideline 2.1). The dialog must come after the first frame so the
/// window is key, and before AdMob can read the IDFA.
Future<void> requestTrackingThenAds() async {
  if (Platform.isIOS) {
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
    } catch (error) {
      debugPrint('ATT request failed: $error');
    }
  }
  await RewardedAdService.instance.initialize();
}
