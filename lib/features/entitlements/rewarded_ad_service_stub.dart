import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RewardedAdOutcome { earned, dismissed, unavailable }

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService.instance,
);

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  bool get isSupported => false;
  bool get hasAd => false;
  bool get privacyOptionsRequired => false;

  Future<void> initialize() async {}

  Future<void> showPrivacyOptions() async {}

  Future<RewardedAdOutcome> show() async => RewardedAdOutcome.unavailable;
}
