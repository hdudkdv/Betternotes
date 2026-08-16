import 'dart:typed_data';

/// Object store for gzip page bodies and binary assets.
///
/// Firebase Storage is the default. Cloudflare R2 is used when
/// `--dart-define=CLOUD_R2_ACCOUNT_ID=...` (and access keys) are set.
abstract class CloudStore {
  Future<void> put(
    String key,
    Uint8List bytes, {
    String? contentType,
  });

  Future<Uint8List?> get(String key);

  Future<void> delete(String key);
}
