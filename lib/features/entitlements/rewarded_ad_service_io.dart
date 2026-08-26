import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'store_environment.dart';

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
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static const _maxLoadAttempts = 8;
  static const _showTimeout = Duration(seconds: 25);

  bool _initialized = false;
  bool _loading = false;
  bool _canRequestAds = false;
  bool _consentUpdateFailed = false;
  bool _useTestAds = AdConfig.useTestAds;
  int _failedAttempts = 0;
  RewardedAd? _ad;
  Completer<void>? _loadWait;
  var _privacyOptions = PrivacyOptionsRequirementStatus.unknown;

  bool get isSupported => AdConfig.isSupported;

  bool get hasAd => _ad != null;

  bool get isLoading => _loading;

  /// True when the GDPR consent form must stay reachable from the settings.
  bool get privacyOptionsRequired =>
      _privacyOptions == PrivacyOptionsRequirementStatus.required;

  /// Gathers consent, starts the SDK and warms up the first ad.
  Future<void> initialize() async {
    if (_initialized || !AdConfig.isSupported) return;
    try {
      if (await isAppStoreSandbox()) {
        _useTestAds = true;
      }
      // Let the first frame become key before any system/UMP dialog.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _gatherConsent();
      await _requestTrackingAuthorization();
      await MobileAds.instance.initialize();
      _initialized = true;
      // NPA ads are allowed without tracking. Never wait on UMP to fill.
      _canRequestAds = true;
      unawaited(_load());
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
      _initialized = true;
      _canRequestAds = true;
      _useTestAds = true;
      unawaited(_load());
    }
  }

  /// Warm an ad if none is ready. Safe to call from any screen.
  Future<void> preload() async {
    if (!AdConfig.isSupported) return;
    if (!_initialized) await initialize();
    if (_ad != null) return;
    _failedAttempts = 0;
    await _load();
  }

  Future<void> _gatherConsent() async {
    try {
      await _gatherConsentInner();
    } catch (error) {
      debugPrint('Consent failed: $error');
      _consentUpdateFailed = true;
      _canRequestAds = true;
    }
  }

  Future<TrackingStatus> _attStatus() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingStatus.notSupported;
    }
    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (error) {
      debugPrint('ATT status failed: $error');
      return TrackingStatus.notDetermined;
    }
  }

  bool _trackingAlreadyRefused(TrackingStatus status) =>
      status == TrackingStatus.denied || status == TrackingStatus.restricted;

  Future<void> _gatherConsentInner() async {
    final att = await _attStatus();
    // Apple 5.1.1(iv): after "Ask App Not to Track", do not present another
    // form that asks to allow tracking (UMP personalized-ads consent).
    if (_trackingAlreadyRefused(att)) {
      debugPrint('ATT already refused; skipping advertising consent form');
      _canRequestAds = true;
      _privacyOptions = PrivacyOptionsRequirementStatus.notRequired;
      return;
    }

    final consent = ConsentInformation.instance;
    final updated = Completer<void>();
    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      updated.complete,
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        _consentUpdateFailed = true;
        if (!updated.isCompleted) updated.complete();
      },
    );
    try {
      await updated.future.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      debugPrint('Consent info update timed out');
      _consentUpdateFailed = true;
      _canRequestAds = true;
      return;
    }

    // If ATT was denied while the info update ran, still do not show UMP.
    if (_trackingAlreadyRefused(await _attStatus())) {
      _canRequestAds = true;
      _privacyOptions = PrivacyOptionsRequirementStatus.notRequired;
      return;
    }

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
    if (!_canRequestAds &&
        (_consentUpdateFailed ||
            _privacyOptions == PrivacyOptionsRequirementStatus.unknown)) {
      _canRequestAds = true;
    }
  }

  Future<void> _requestTrackingAuthorization() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // Only prompt while still undetermined — never after a denial.
      if (await AppTrackingTransparency.trackingAuthorizationStatus !=
          TrackingStatus.notDetermined) {
        return;
      }
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (error) {
      debugPrint('ATT request failed: $error');
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!AdConfig.isSupported) return;
    if (_trackingAlreadyRefused(await _attStatus())) return;
    final dismissed = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint('Privacy options form failed: ${error.message}');
      }
      if (!dismissed.isCompleted) dismissed.complete();
    });
    await dismissed.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) {
      _failedAttempts = 0;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final unitId = _useTestAds
        ? AdConfig.rewardedTestUnitId
        : AdConfig.rewardedUnitId;
    if (!AdConfig.isSupported || unitId == null) return;
    if (!_initialized) return;
    if (_ad != null) return;
    if (_loading) {
      await _loadWait?.future;
      return;
    }
    if (_failedAttempts >= _maxLoadAttempts) {
      if (!_useTestAds) {
        debugPrint('Live rewarded ads empty; falling back to Google test ads');
        _useTestAds = true;
        _failedAttempts = 0;
        unawaited(_load());
      }
      return;
    }

    _canRequestAds = true;
    _loading = true;
    final wait = Completer<void>();
    _loadWait = wait;

    var nonPersonalized = false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        nonPersonalized = status != TrackingStatus.authorized;
      } catch (_) {}
    }

    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: AdRequest(nonPersonalizedAds: nonPersonalized),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _failedAttempts = 0;
            _finishLoad(wait);
          },
          onAdFailedToLoad: (error) {
            _failedAttempts++;
            debugPrint('Rewarded ad failed to load: ${error.message}');
            _finishLoad(wait);
          },
        ),
      );
      await wait.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('Rewarded ad load timed out');
          _finishLoad(wait);
        },
      );
    } catch (error) {
      _failedAttempts++;
      debugPrint('Rewarded ad load threw: $error');
      _finishLoad(wait);
    }

    if (_ad == null && !_useTestAds) {
      _useTestAds = true;
      _failedAttempts = 0;
      unawaited(_load());
      return;
    }

    if (_ad == null && _failedAttempts < _maxLoadAttempts) {
      final seconds = (2 * _failedAttempts).clamp(2, 16);
      unawaited(
        Future<void>.delayed(Duration(seconds: seconds), () {
          if (_ad == null && !_loading) unawaited(_load());
        }),
      );
    }
  }

  void _finishLoad(Completer<void> wait) {
    _loading = false;
    if (!wait.isCompleted) wait.complete();
    if (identical(_loadWait, wait)) _loadWait = null;
  }

  /// Presents a rewarded ad and resolves once it has been closed.
  Future<RewardedAdOutcome> show() async {
    if (!AdConfig.isSupported) return RewardedAdOutcome.unavailable;
    if (!_initialized) await initialize();
    _canRequestAds = true;

    if (_ad == null) {
      _failedAttempts = 0;
      try {
        await _load().timeout(_showTimeout);
      } on TimeoutException {
        debugPrint('Rewarded ad was not ready in time');
      }
    }

    if (_ad == null && !_useTestAds) {
      _useTestAds = true;
      _failedAttempts = 0;
      try {
        await _load().timeout(_showTimeout);
      } on TimeoutException {
        debugPrint('Test rewarded ad was not ready in time');
      }
    }

    final ad = _ad;
    if (ad == null) return RewardedAdOutcome.unavailable;
    _ad = null;
    // Start the next fill immediately so the following tap is instant.
    unawaited(_load());

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
      unawaited(_load());
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
