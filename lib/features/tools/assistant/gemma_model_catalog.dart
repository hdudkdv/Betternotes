import 'gemma_device_profile.dart';

class GemmaModelSpec {
  const GemmaModelSpec({
    required this.tier,
    required this.id,
    required this.fileName,
    required this.url,
    this.fallbackUrl,
    required this.sizeMb,
    required this.minRamMb,
    required this.maxTokens,
    required this.preferGpu,
  });

  final GemmaModelTier tier;
  final String id;
  final String fileName;

  /// Public Firebase Storage URL — no Hugging Face token for end users.
  final String url;

  /// Official Hugging Face file, only used if Firebase is empty and a
  /// developer token is present.
  final String? fallbackUrl;
  final int sizeMb;
  final int minRamMb;
  final int maxTokens;
  final bool preferGpu;

  List<String> get downloadUrls => [
    url,
    if (fallbackUrl != null && fallbackUrl!.isNotEmpty) fallbackUrl!,
  ];
}

/// On-device Gemma weights. Production downloads come from our Storage bucket.
abstract final class GemmaModelCatalog {
  static const lite = GemmaModelSpec(
    tier: GemmaModelTier.lite,
    id: 'gemma3-270m',
    fileName: 'gemma3-270m-it-q8.litertlm',
    url:
        'https://firebasestorage.googleapis.com/v0/b/notis-2dee0.firebasestorage.app/o/gemma%2Fgemma3-270m-it-q8.litertlm?alt=media',
    fallbackUrl:
        'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.litertlm',
    sizeMb: 300,
    minRamMb: 2048,
    maxTokens: 512,
    preferGpu: false,
  );

  static const balanced = GemmaModelSpec(
    tier: GemmaModelTier.balanced,
    id: 'gemma3-1b',
    fileName: 'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
    url:
        'https://firebasestorage.googleapis.com/v0/b/notis-2dee0.firebasestorage.app/o/gemma%2FGemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm?alt=media',
    fallbackUrl:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm',
    sizeMb: 530,
    minRamMb: 4096,
    maxTokens: 1024,
    preferGpu: true,
  );

  static const full = GemmaModelSpec(
    tier: GemmaModelTier.full,
    id: 'gemma3n-e2b',
    fileName: 'gemma-3n-E2B-it-int4.litertlm',
    url:
        'https://firebasestorage.googleapis.com/v0/b/notis-2dee0.firebasestorage.app/o/gemma%2Fgemma-3n-E2B-it-int4.litertlm?alt=media',
    fallbackUrl:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/resolve/main/gemma-3n-E2B-it-int4.litertlm',
    sizeMb: 3100,
    minRamMb: 7168,
    maxTokens: 2048,
    preferGpu: true,
  );

  static const all = <GemmaModelSpec>[lite, balanced, full];

  static GemmaModelSpec byTier(GemmaModelTier tier) => switch (tier) {
    GemmaModelTier.lite => lite,
    GemmaModelTier.balanced => balanced,
    GemmaModelTier.full => full,
  };

  static GemmaModelSpec? byId(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }
}
