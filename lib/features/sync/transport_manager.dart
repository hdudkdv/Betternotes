import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a persisted delta should go next.
enum TransportRoute { p2p, cloud, queued }

/// Hybrid router: P2P if a nearby session is up, else premium cloud, else queue.
class TransportManager extends ChangeNotifier {
  bool p2pActive = false;
  bool cloudPremium = false;
  bool cloudReachable = false;

  TransportRoute get preferredRoute {
    if (p2pActive) return TransportRoute.p2p;
    if (cloudPremium && cloudReachable) return TransportRoute.cloud;
    return TransportRoute.queued;
  }

  void setP2pActive(bool active) {
    if (p2pActive == active) return;
    p2pActive = active;
    notifyListeners();
  }

  void setCloud({required bool premium, required bool reachable}) {
    if (cloudPremium == premium && cloudReachable == reachable) return;
    cloudPremium = premium;
    cloudReachable = reachable;
    notifyListeners();
  }

  /// Persist is always local-first. The return value tells callers how to send.
  TransportRoute routeAfterLocalPersist() => preferredRoute;
}

final transportManagerProvider = ChangeNotifierProvider<TransportManager>((
  ref,
) {
  return TransportManager();
});
