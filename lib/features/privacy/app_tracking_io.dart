import '../entitlements/rewarded_ad_service.dart';

/// Starts ads after the first frame.
///
/// Consent order (Apple 5.1.1(iv)):
/// 1. GDPR/UMP form first, but only if tracking was not already denied.
/// 2. App Tracking Transparency once, only while status is notDetermined.
/// 3. Never show a second tracking request after "Ask App Not to Track".
Future<void> requestTrackingThenAds() async {
  await RewardedAdService.instance.initialize();
}
