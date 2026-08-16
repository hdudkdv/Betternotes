import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/entitlements/entitlement_model.dart';
import 'package:betternotes/features/packs/pack_catalog.dart';

void main() {
  test('marketplace groups cover every extra once', () {
    final grouped = <String>[];
    for (final group in PackCatalog.groups) {
      grouped.addAll(group.keys);
    }
    expect(grouped.toSet(), FeatureKeys.marketplace.toSet());
    expect(grouped.length, FeatureKeys.marketplace.length);
  });

  test('every themed pack sits in a group', () {
    for (final pack in PackCatalog.all) {
      expect(
        PackCatalog.groups.any((group) => group.keys.contains(pack.key)),
        isTrue,
        reason: pack.key,
      );
    }
  });
}
