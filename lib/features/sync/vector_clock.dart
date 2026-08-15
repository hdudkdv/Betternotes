/// Per-device Lamport-style vector clock for CRDT deltas.
class VectorClock {
  const VectorClock(this.ticks);

  final Map<String, int> ticks;

  factory VectorClock.empty() => const VectorClock({});

  factory VectorClock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VectorClock.empty();
    return VectorClock({
      for (final e in json.entries) e.key: (e.value as num).toInt(),
    });
  }

  Map<String, dynamic> toJson() => ticks;

  VectorClock increment(String deviceId) {
    final next = Map<String, int>.from(ticks);
    next[deviceId] = (next[deviceId] ?? 0) + 1;
    return VectorClock(next);
  }

  VectorClock merge(VectorClock other) {
    final next = Map<String, int>.from(ticks);
    for (final e in other.ticks.entries) {
      final current = next[e.key] ?? 0;
      if (e.value > current) next[e.key] = e.value;
    }
    return VectorClock(next);
  }

  /// True when [other] is not strictly before this clock (missing / concurrent).
  bool happensBefore(VectorClock other) {
    if (ticks.isEmpty) return other.ticks.isNotEmpty;
    var strictlyLess = false;
    for (final e in ticks.entries) {
      final theirs = other.ticks[e.key] ?? 0;
      if (e.value > theirs) return false;
      if (e.value < theirs) strictlyLess = true;
    }
    for (final e in other.ticks.entries) {
      if (!ticks.containsKey(e.key) && e.value > 0) strictlyLess = true;
    }
    return strictlyLess;
  }
}
