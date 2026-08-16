import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/providers/library_providers.dart';

enum AppTier { free, pro, proPlus, teacher }

/// Unlockable / gated capabilities (Phase 1: local only).
abstract final class FeatureKeys {
  static const premiumPaper = 'premiumPaper';
  static const premiumCover = 'premiumCover';
  static const audioTranscription = 'audioTranscription';
  static const pdfCompress = 'pdfCompress';
  static const handwritingOcr = 'handwritingOcr';
  static const noForcedAds = 'noForcedAds';
  static const sessionCollab = 'sessionCollab';
  static const asyncCollab = 'asyncCollab';
  static const whiteboard = 'whiteboard';
  static const cloudSync = 'cloudSync';
  static const aiAssistant = 'aiAssistant';
  static const studyMode = 'studyMode';

  static const all = <String>[
    premiumPaper,
    premiumCover,
    audioTranscription,
    pdfCompress,
    handwritingOcr,
    noForcedAds,
    sessionCollab,
    asyncCollab,
    whiteboard,
    cloudSync,
    aiAssistant,
    studyMode,
  ];

  static int coinCost(String key) => switch (key) {
    premiumPaper || premiumCover => 20,
    pdfCompress => 30,
    handwritingOcr || audioTranscription || cloudSync => 50,
    whiteboard || aiAssistant => 80,
    sessionCollab || studyMode => 40,
    asyncCollab => 100,
    noForcedAds => 60,
    _ => 25,
  };
}

class EntitlementState extends Equatable {
  const EntitlementState({
    this.tier = AppTier.free,
    this.coins = 0,
    this.unlocked = const {},
    this.serverCostEuro = 12,
    this.donationsCoveredEuro = 0,
    this.supportUrl = 'https://ko-fi.com/',
  });

  final AppTier tier;
  final int coins;
  final Set<String> unlocked;
  final int serverCostEuro;
  final int donationsCoveredEuro;
  final String supportUrl;

  bool get isProOrHigher =>
      tier == AppTier.pro || tier == AppTier.proPlus || tier == AppTier.teacher;

  bool get isTeacher => tier == AppTier.teacher;

  bool hasAccess(String feature) {
    if (unlocked.contains(feature)) return true;
    switch (tier) {
      case AppTier.free:
        return false;
      case AppTier.pro:
        return const {
          FeatureKeys.noForcedAds,
          FeatureKeys.premiumPaper,
          FeatureKeys.premiumCover,
          FeatureKeys.pdfCompress,
          FeatureKeys.sessionCollab,
          FeatureKeys.cloudSync,
        }.contains(feature);
      case AppTier.proPlus:
        return feature != FeatureKeys.whiteboard;
      case AppTier.teacher:
        return true;
    }
  }

  EntitlementState copyWith({
    AppTier? tier,
    int? coins,
    Set<String>? unlocked,
    int? serverCostEuro,
    int? donationsCoveredEuro,
    String? supportUrl,
  }) {
    return EntitlementState(
      tier: tier ?? this.tier,
      coins: coins ?? this.coins,
      unlocked: unlocked ?? this.unlocked,
      serverCostEuro: serverCostEuro ?? this.serverCostEuro,
      donationsCoveredEuro: donationsCoveredEuro ?? this.donationsCoveredEuro,
      supportUrl: supportUrl ?? this.supportUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier.name,
    'coins': coins,
    'unlocked': unlocked.toList(),
    'serverCostEuro': serverCostEuro,
    'donationsCoveredEuro': donationsCoveredEuro,
    'supportUrl': supportUrl,
  };

  factory EntitlementState.fromJson(Map<String, dynamic> json) {
    return EntitlementState(
      tier: AppTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => AppTier.free,
      ),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      unlocked: {
        for (final u in (json['unlocked'] as List? ?? const [])) u as String,
      },
      serverCostEuro: (json['serverCostEuro'] as num?)?.toInt() ?? 12,
      donationsCoveredEuro:
          (json['donationsCoveredEuro'] as num?)?.toInt() ?? 0,
      supportUrl: json['supportUrl'] as String? ?? 'https://ko-fi.com/',
    );
  }

  @override
  List<Object?> get props => [
    tier,
    coins,
    unlocked,
    serverCostEuro,
    donationsCoveredEuro,
    supportUrl,
  ];
}

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier(this._prefs) : super(const EntitlementState()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'entitlementsV1';

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = EntitlementState.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setTier(AppTier tier) async {
    state = state.copyWith(tier: tier);
    await _save();
  }

  Future<void> addCoins(int amount) async {
    state = state.copyWith(coins: (state.coins + amount).clamp(0, 999999));
    await _save();
  }

  Future<bool> unlockWithCoins(String feature) async {
    if (state.hasAccess(feature)) return true;
    final cost = FeatureKeys.coinCost(feature);
    if (state.coins < cost) return false;
    state = state.copyWith(
      coins: state.coins - cost,
      unlocked: {...state.unlocked, feature},
    );
    await _save();
    return true;
  }

  Future<void> unlockFeature(String feature) async {
    state = state.copyWith(unlocked: {...state.unlocked, feature});
    await _save();
  }

  Future<void> setSupportMeta({
    int? serverCostEuro,
    int? donationsCoveredEuro,
    String? supportUrl,
  }) async {
    state = state.copyWith(
      serverCostEuro: serverCostEuro,
      donationsCoveredEuro: donationsCoveredEuro,
      supportUrl: supportUrl,
    );
    await _save();
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, EntitlementState>((ref) {
      return EntitlementNotifier(ref.watch(sharedPreferencesProvider));
    });
