import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/tools/assistant/gemma_device_profile.dart';

void main() {
  test('low RAM picks the lite Gemma', () {
    const profile = GemmaDeviceProfile(ramMb: 2800, cpuCores: 8, benchMs: 40);
    expect(profile.recommended, GemmaModelTier.lite);
  });

  test('mid-range picks the 1B model', () {
    const profile = GemmaDeviceProfile(ramMb: 4096, cpuCores: 6, benchMs: 100);
    expect(profile.recommended, GemmaModelTier.balanced);
  });

  test('strong device picks the full model', () {
    const profile = GemmaDeviceProfile(ramMb: 8192, cpuCores: 8, benchMs: 50);
    expect(profile.recommended, GemmaModelTier.full);
  });
}
