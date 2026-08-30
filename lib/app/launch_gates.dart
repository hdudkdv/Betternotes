/// 1.0 ships the core notebook app only.
///
/// Store purchases, coins, ads-for-coins and marketplace unlocks stay in
/// the binary but are not offered. Flip this when IAP is ready for review.
abstract final class LaunchGates {
  static const commerceEnabled = false;
}
