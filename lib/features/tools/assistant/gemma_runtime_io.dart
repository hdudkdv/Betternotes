import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gemma_device_profile.dart';
import 'gemma_model_catalog.dart';

enum GemmaPhase { idle, checking, downloading, ready, failed }

final gemmaRuntimeProvider = ChangeNotifierProvider<GemmaRuntime>(
  (ref) => GemmaRuntime.instance,
);

class GemmaRuntime extends ChangeNotifier {
  GemmaRuntime._();

  static final GemmaRuntime instance = GemmaRuntime._();

  static const _prefsId = 'gemmaModelId';
  static const _envToken = String.fromEnvironment('HUGGINGFACE_TOKEN');

  GemmaPhase phase = GemmaPhase.idle;
  double progress = 0;
  String? error;
  GemmaDeviceProfile? lastProfile;
  GemmaModelSpec? spec;

  bool _engineReady = false;
  bool _restored = false;
  InferenceModel? _model;
  InferenceChat? _chat;

  bool get isSupported => true;
  bool get isReady => phase == GemmaPhase.ready && spec != null;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefsId);
      final saved = id == null ? null : GemmaModelCatalog.byId(id);
      if (saved == null) return;
      spec = saved;
      await _ensureEngine();
      await _openModel(saved);
      phase = GemmaPhase.ready;
      error = null;
    } catch (e) {
      phase = GemmaPhase.idle;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<GemmaDeviceProfile> runCheck() async {
    phase = GemmaPhase.checking;
    error = null;
    progress = 0;
    notifyListeners();
    lastProfile = await GemmaDeviceProbe.measure();
    spec = GemmaModelCatalog.byTier(lastProfile!.recommended);
    phase = GemmaPhase.idle;
    notifyListeners();
    return lastProfile!;
  }

  Future<void> installRecommended() async {
    lastProfile ??= await runCheck();
    await installTier(lastProfile!.recommended);
  }

  Future<void> installTier(GemmaModelTier tier) async {
    final chosen = GemmaModelCatalog.byTier(tier);
    spec = chosen;
    phase = GemmaPhase.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      await _ensureEngine();
      await _closeSession();
      Object? lastError;
      var installed = false;
      for (final url in chosen.downloadUrls) {
        final needsToken = url.contains('huggingface.co');
        if (needsToken && _token.isEmpty) continue;
        try {
          await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
              .fromNetwork(url, token: needsToken ? _token : null)
              .withProgress((value) {
                progress = (value / 100).clamp(0, 1);
                notifyListeners();
              })
              .install();
          installed = true;
          break;
        } catch (e) {
          lastError = e;
        }
      }
      if (!installed) {
        throw lastError ?? StateError('Gemma-Modell nicht erreichbar.');
      }
      await _openModel(chosen);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsId, chosen.id);
      phase = GemmaPhase.ready;
      progress = 1;
    } catch (e) {
      phase = GemmaPhase.failed;
      error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> complete(
    String user, {
    required bool german,
    String? extra,
  }) async {
    if (!isReady || _chat == null) return null;
    final buffer = StringBuffer(user.trim());
    if (extra != null && extra.trim().isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(extra.trim());
    }
    try {
      await _chat!.addQueryChunk(
        Message.text(text: buffer.toString(), isUser: true),
      );
      final raw = await _chat!.generateChatResponse();
      return _asText(raw);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void resetConversation() {
    _chat = null;
    final chosen = spec;
    if (chosen != null && _model != null) {
      _openChat(chosen);
    }
  }

  Future<void> _ensureEngine() async {
    if (_engineReady) return;
    FlutterGemma.initialize(
      huggingFaceToken: _token.isEmpty ? null : _token,
      maxDownloadRetries: 8,
    );
    _engineReady = true;
  }

  Future<void> _openModel(GemmaModelSpec chosen) async {
    await _closeSession();
    _model = await FlutterGemma.getActiveModel(
      maxTokens: chosen.maxTokens,
      preferredBackend: chosen.preferGpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu,
    );
    await _openChat(chosen);
  }

  Future<void> _openChat(GemmaModelSpec chosen) async {
    final model = _model;
    if (model == null) return;
    _chat = await model.createChat(systemInstruction: _systemPrompt);
  }

  Future<void> _closeSession() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
    _chat = null;
  }

  String get _token => _envToken.trim();

  static String _asText(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    try {
      final token = (raw as dynamic).token;
      if (token is String && token.trim().isNotEmpty) return token.trim();
    } catch (_) {}
    final text = raw.toString().trim();
    if (text.startsWith('Instance of')) return '';
    return text;
  }

  static const _systemPrompt =
      'You are Gemma, a teacher inside the Notis notes app. '
      'Guide the student like a teacher: explain connections and the method. '
      'In maths, never compute the result and never write the final number. '
      'The student uses their own calculator. '
      'Never write a finished exam sentence or a complete interpretation. '
      'Keep replies short (4–8 sentences). '
      'Answer in the same language the student used.';
}
