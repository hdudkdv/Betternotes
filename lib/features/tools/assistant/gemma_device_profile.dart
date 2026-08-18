import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'gemma_host.dart';

enum GemmaModelTier { lite, balanced, full }

/// RAM, cores and a short CPU probe — used to pick a Gemma weight.
class GemmaDeviceProfile {
  const GemmaDeviceProfile({
    required this.ramMb,
    required this.cpuCores,
    required this.benchMs,
    this.deviceLabel = '',
  });

  final int ramMb;
  final int cpuCores;
  final int benchMs;
  final String deviceLabel;

  GemmaModelTier get recommended {
    if (ramMb > 0 && ramMb < 3200) return GemmaModelTier.lite;
    if (cpuCores > 0 && cpuCores <= 2) return GemmaModelTier.lite;
    if (benchMs >= 220) return GemmaModelTier.lite;
    if (ramMb >= 7500 && cpuCores >= 6 && benchMs > 0 && benchMs < 90) {
      return GemmaModelTier.full;
    }
    if (ramMb > 0 && ramMb < 5500) return GemmaModelTier.balanced;
    if (benchMs >= 120) return GemmaModelTier.balanced;
    if (ramMb >= 7500) return GemmaModelTier.full;
    return GemmaModelTier.balanced;
  }
}

class GemmaDeviceProbe {
  static Future<GemmaDeviceProfile> measure({
    int? ramMb,
    int? cpuCores,
    int? benchMs,
  }) async {
    final cores = cpuCores ?? GemmaHost.processorCount;
    final ram = ramMb ?? await _ramMb();
    final bench = benchMs ?? await compute(_cpuBenchMs, 0) ?? 80;
    final label = await _label();
    return GemmaDeviceProfile(
      ramMb: ram,
      cpuCores: cores,
      benchMs: bench,
      deviceLabel: label,
    );
  }

  static Future<int> _ramMb() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (GemmaHost.isAndroid) {
        final info = await plugin.androidInfo;
        final physical = info.physicalRamSize;
        if (physical > 0) return physical;
      } else if (GemmaHost.isIOS) {
        final info = await plugin.iosInfo;
        return _iosRamMb(info.utsname.machine);
      } else if (GemmaHost.isWindows || GemmaHost.isMacOS) {
        return 8192;
      }
    } catch (_) {}
    return 4096;
  }

  static Future<String> _label() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (GemmaHost.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (GemmaHost.isIOS) {
        final info = await plugin.iosInfo;
        return info.utsname.machine;
      }
      if (GemmaHost.isWindows) return 'Windows';
      if (GemmaHost.isMacOS) return 'macOS';
    } catch (_) {}
    return '';
  }

  /// Conservative RAM guesses from machine id. Unknown iPads stay at 4 GB.
  static int _iosRamMb(String machine) {
    final id = machine.toLowerCase();
    if (id.contains('ipad16') || id.contains('ipad15')) return 8192;
    if (id.contains('ipad14')) return 8192;
    if (id.contains('ipad13')) return 4096;
    if (id.contains('ipad11') || id.contains('ipad12')) return 4096;
    if (id.contains('iphone17') || id.contains('iphone16')) return 8192;
    if (id.contains('iphone15') || id.contains('iphone14')) return 6144;
    if (id.contains('iphone13') || id.contains('iphone12')) return 4096;
    return 4096;
  }
}

int _cpuBenchMs(int _) {
  final sw = Stopwatch()..start();
  var x = 1.0001;
  for (var i = 0; i < 900000; i++) {
    x = x * 1.0000001 + 0.0000003;
  }
  if (!x.isFinite) return 9999;
  return sw.elapsedMilliseconds;
}
