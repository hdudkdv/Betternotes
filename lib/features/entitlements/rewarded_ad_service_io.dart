import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

enum RewardedAdOutcome {
  /// The user watched the ad long enough to earn the reward.
  earned,

  /// The ad was shown but closed before the reward was granted.
  dismissed,

  /// No ad could be shown. Release builds must not fake a reward.
  unavailable,
}

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService.instance,
);

/// Loads and presents AdMob rewarded ads, keeping one ad warm in the background.
///
/// Every failure path is non-fatal: on unsupported platforms or when no ad
/// fills, [show] reports [RewardedAdOutcome.unavailable] so the app can keep
/// working without ads.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static const _maxLoadAttempts = 3;

  bool _initialized = false;
  bool _loading = false;
  bool _canRequestAds = false;
  int _failedAttempts = 0;
  RewardedAd? _ad;
  var _privacyOptions = PrivacyOptionsRequirementStatus.unknown;

  bool get isSupported => AdConfig.isSupported;

  bool get hasAd => _ad != null;

  /// True when the GDPR consent form must stay reachable from the settings.
  bool get privacyOptionsRequired =>
      _privacyOptions == PrivacyOptionsRequirementStatus.required;

  /// Gathers consent, starts the SDK and warms up the first ad.
  ///
  /// Safe to call more than once.
  Future<void> initialize() async {
    if (_initialized || !AdConfig.isSupported) return;
    try {
      await _gatherConsent();
      await _requestTrackingAuthorization();
      await MobileAds.instance.initialize();
      _initialized = true;
      if (_canRequestAds) unawaited(_load());
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }
  }

  /// Runs the UMP consent flow, which is mandatory for EEA and UK users.
  ///
  /// Ads are only requested once the user can legally be served them.
  Future<void> _gatherConsent() async {
    final consent = ConsentInformation.instance;
    final updated = Completer<void>();
    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updated.complete,
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future;

    final dismissed = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        debugPrint('Consent form failed: ${error.message}');
      }
      if (!dismissed.isCompleted) dismissed.complete();
    });
    await dismissed.future;

    _canRequestAds = await consent.canRequestAds();
    _privacyOptions = await consent.getPrivacyOptionsRequirementStatus();
  }

  /// ATT after UMP so iOS 14.5+ can serve personalized (and more) ads.
  Future<void> _requestTrackingAuthorization() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      // Presenting ATT in the same frame as the consent form is rejected.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (error) {
      debugPrint('ATT request failed: $error');
    }
  }

  /// Reopens the consent form so users can change their ad preferences.
  Future<void> showPrivacyOptions() async {
    if (!AdConfig.isSupported) return;
    final dismissed = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint('Privacy options form failed: ${error.message}');
      }
      if (!dismissed.isCompleted) dismissed.complete();
    });
    await dismissed.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) unawaited(_load());
  }

  Future<void> _load() async {
    final unitId = AdConfig.rewardedUnitId;
    if (!_initialized || _loading || _ad != null || unitId == null) return;
    if (!_canRequestAds) return;
    if (_failedAttempts >= _maxLoadAttempts) return;
    _loading = true;

    final completer = Completer<void>();
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _failedAttempts = 0;
          _loading = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          _failedAttempts++;
          _loading = false;
          debugPrint('Rewarded ad failed to load: ${error.message}');
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  /// Presents a rewarded ad and resolves once it has been closed.
  Future<RewardedAdOutcome> show() async {
    if (!AdConfig.isSupported) return RewardedAdOutcome.unavailable;
    if (!_initialized) await initialize();
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (error) {
      debugPrint('canRequestAds failed: $error');
    }
    if (_ad == null) {
      // Reset the backoff so an explicit user request always gets one attempt.
      _failedAttempts = 0;
      await _load();
    }
    final ad = _ad;
    if (ad == null) return RewardedAdOutcome.unavailable;
    _ad = null;

    var earned = false;
    final closed = Completer<RewardedAdOutcome>();
    void finish(RewardedAdOutcome outcome) {
      if (!closed.isCompleted) closed.complete(outcome);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_load());
        finish(earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('Rewarded ad failed to show: ${error.message}');
        unawaited(_load());
        finish(RewardedAdOutcome.unavailable);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (error) {
      ad.dispose();
      debugPrint('Rewarded ad threw while showing: $error');
      return RewardedAdOutcome.unavailable;
    }
    return closed.future;
  }

  @visibleForTesting
  void disposeAd() {
    _ad?.dispose();
    _ad = null;
  }
}
