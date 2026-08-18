import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/providers/library_providers.dart';

enum AppTier { free, lite, pro, proPlus, teacher }

/// Paid level used by the six public plans (role × this).
enum PaidTier { free, lite, pro }

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
  static const chartPack = 'chartPack';
  static const calcPlus = 'calcPlus';
  static const formulaPack = 'formulaPack';
  static const helperPack = 'helperPack';
  static const packDev = 'packDev';
  static const packEdu = 'packEdu';
  static const packRpg = 'packRpg';
  static const packCulinary = 'packCulinary';
  static const packAgile = 'packAgile';
  static const packMusic = 'packMusic';
  static const packAcademic = 'packAcademic';
  static const packFitness = 'packFitness';
  static const packTravel = 'packTravel';
  static const packFreelance = 'packFreelance';

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
    chartPack,
    calcPlus,
    formulaPack,
    helperPack,
    packDev,
    packEdu,
    packRpg,
    packCulinary,
    packAgile,
    packMusic,
    packAcademic,
    packFitness,
    packTravel,
    packFreelance,
  ];

  /// Marketplace extras. Free/Lite buy with coins; Pro loans 5 at a time.
  static const marketplace = <String>[
    aiAssistant,
    pdfCompress,
    handwritingOcr,
    audioTranscription,
    chartPack,
    calcPlus,
    formulaPack,
    helperPack,
    packDev,
    packEdu,
    packRpg,
    packCulinary,
    packAgile,
    packMusic,
    packAcademic,
    packFitness,
    packTravel,
    packFreelance,
  ];

  static int coinCost(String key) => switch (key) {
    premiumPaper || premiumCover => 20,
    pdfCompress || formulaPack || helperPack => 30,
    calcPlus => 35,
    handwritingOcr || audioTranscription || cloudSync => 50,
    chartPack ||
    sessionCollab ||
    studyMode ||
    packCulinary ||
    packTravel => 40,
    packDev ||
    packEdu ||
    packRpg ||
    packAgile ||
    packMusic ||
    packAcademic ||
    packFitness ||
    packFreelance => 55,
    whiteboard || aiAssistant => 80,
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
    this.lastDailyCoinDay,
    this.loaned = const {},
  });

  final AppTier tier;
  final int coins;
  final Set<String> unlocked;
  final int serverCostEuro;
  final int donationsCoveredEuro;
  final String supportUrl;

  /// Local calendar day (`yyyy-MM-dd`) of the last premium coin grant.
  final String? lastDailyCoinDay;

  /// Marketplace extras currently borrowed (Pro: up to 5).
  final Set<String> loaned;

  bool get isProOrHigher => paidTier != PaidTier.free;

  /// Legacy flag from stored `AppTier.teacher`. Role lives on [AppSettings].
  bool get isTeacher => tier == AppTier.teacher;

  PaidTier get paidTier => switch (tier) {
    AppTier.free => PaidTier.free,
    AppTier.lite => PaidTier.lite,
    AppTier.pro || AppTier.proPlus || AppTier.teacher => PaidTier.pro,
  };

  int get marketplacePurchases => unlocked
      .where(FeatureKeys.marketplace.contains)
      .length;

  int get marketplaceLoans =>
      loaned.where(FeatureKeys.marketplace.contains).length;

  int get marketplaceBuyLimit => switch (paidTier) {
    PaidTier.lite => 3,
    _ => 0,
  };

  int get marketplaceLoanLimit => switch (paidTier) {
    PaidTier.pro => 5,
    _ => 0,
  };

  /// Free and Lite spend coins. Lite's first 3 are the included permanent buys;
  /// further Lite unlocks still cost coins (from ads). Pro uses loans instead.
  bool get canBuyMarketplace => paidTier != PaidTier.pro;

  bool get canLoanMarketplace =>
      paidTier == PaidTier.pro && marketplaceLoans < marketplaceLoanLimit;

  /// Ads are only a coin faucet: Free always, Lite after the 3 permanent buys.
  bool get adsEnabled => switch (paidTier) {
    PaidTier.free => true,
    PaidTier.lite => marketplacePurchases >= marketplaceBuyLimit,
    PaidTier.pro => false,
  };

  static String dayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get canClaimDailyCoins => false;

  bool hasAccess(String feature, {bool isTeacherRole = false}) {
    if (unlocked.contains(feature)) return true;
    if (loaned.contains(feature) && paidTier == PaidTier.pro) return true;
    if (FeatureKeys.marketplace.contains(feature)) return false;
    if (feature == FeatureKeys.whiteboard) {
      return isTeacherRole && paidTier == PaidTier.pro;
    }
    switch (paidTier) {
      case PaidTier.free:
        return false;
      case PaidTier.lite:
        return const {
          FeatureKeys.premiumPaper,
          FeatureKeys.premiumCover,
          FeatureKeys.sessionCollab,
          FeatureKeys.cloudSync,
          FeatureKeys.studyMode,
        }.contains(feature);
      case PaidTier.pro:
        return feature != FeatureKeys.whiteboard &&
            feature != FeatureKeys.noForcedAds;
    }
  }

  EntitlementState copyWith({
    AppTier? tier,
    int? coins,
    Set<String>? unlocked,
    int? serverCostEuro,
    int? donationsCoveredEuro,
    String? supportUrl,
    String? lastDailyCoinDay,
    Set<String>? loaned,
  }) {
    return EntitlementState(
      tier: tier ?? this.tier,
      coins: coins ?? this.coins,
      unlocked: unlocked ?? this.unlocked,
      serverCostEuro: serverCostEuro ?? this.serverCostEuro,
      donationsCoveredEuro: donationsCoveredEuro ?? this.donationsCoveredEuro,
      supportUrl: supportUrl ?? this.supportUrl,
      lastDailyCoinDay: lastDailyCoinDay ?? this.lastDailyCoinDay,
      loaned: loaned ?? this.loaned,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': switch (paidTier) {
      PaidTier.free => AppTier.free.name,
      PaidTier.lite => AppTier.lite.name,
      PaidTier.pro => AppTier.pro.name,
    },
    'paidTier': paidTier.name,
    'coins': coins,
    'unlocked': unlocked.toList(),
    'serverCostEuro': serverCostEuro,
    'donationsCoveredEuro': donationsCoveredEuro,
    'supportUrl': supportUrl,
    'lastDailyCoinDay': lastDailyCoinDay,
    'loaned': loaned.toList(),
  };

  factory EntitlementState.fromJson(Map<String, dynamic> json) {
    return EntitlementState(
      tier: _tierFromName(
        json['tier'] as String?,
        paid: json['paidTier'] as String?,
      ),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      unlocked: {
        for (final u in (json['unlocked'] as List? ?? const [])) u as String,
      },
      serverCostEuro: (json['serverCostEuro'] as num?)?.toInt() ?? 12,
      donationsCoveredEuro:
          (json['donationsCoveredEuro'] as num?)?.toInt() ?? 0,
      supportUrl: json['supportUrl'] as String? ?? 'https://ko-fi.com/',
      lastDailyCoinDay: json['lastDailyCoinDay'] as String?,
      loaned: {
        for (final u in (json['loaned'] as List? ?? const [])) u as String,
      },
    );
  }

  static AppTier _tierFromName(String? name, {String? paid}) {
    switch (paid) {
      case 'lite':
        return AppTier.lite;
      case 'pro':
        return AppTier.pro;
      case 'free':
        return AppTier.free;
    }
    return switch (name) {
      'lite' => AppTier.lite,
      'pro' => AppTier.lite,
      'proPlus' => AppTier.pro,
      'teacher' => AppTier.pro,
      'free' => AppTier.free,
      _ => AppTier.free,
    };
  }

  @override
  List<Object?> get props => [
    tier,
    coins,
    unlocked,
    serverCostEuro,
    donationsCoveredEuro,
    supportUrl,
    lastDailyCoinDay,
    loaned,
  ];
}

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier(this._prefs) : super(const EntitlementState()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'entitlementsV1';

  void reloadFromPrefs() => _load();

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

  /// Premium users earn the same coin amount as one ad, once per local day.
  Future<int?> claimDailyCoins({int amount = 10}) async {
    if (!state.canClaimDailyCoins) return null;
    state = state.copyWith(
      coins: (state.coins + amount).clamp(0, 999999),
      lastDailyCoinDay: EntitlementState.dayKey(),
    );
    await _save();
    return amount;
  }

  Future<bool> unlockWithCoins(String feature) async {
    if (state.hasAccess(feature)) return true;
    if (FeatureKeys.marketplace.contains(feature) &&
        state.paidTier == PaidTier.pro) {
      return false;
    }
    final cost = FeatureKeys.coinCost(feature);
    if (state.coins < cost) return false;
    state = state.copyWith(
      coins: state.coins - cost,
      unlocked: {...state.unlocked, feature},
    );
    await _save();
    return true;
  }

  Future<bool> borrowFeature(String feature) async {
    if (state.hasAccess(feature)) return true;
    if (!FeatureKeys.marketplace.contains(feature)) return false;
    if (!state.canLoanMarketplace) return false;
    state = state.copyWith(loaned: {...state.loaned, feature});
    await _save();
    return true;
  }

  Future<void> returnLoan(String feature) async {
    state = state.copyWith(
      loaned: {for (final key in state.loaned) if (key != feature) key},
    );
    await _save();
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
