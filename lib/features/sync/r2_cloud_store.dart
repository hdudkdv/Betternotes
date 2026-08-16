import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'cloud_store.dart';

/// S3-compatible Cloudflare R2 backend. Activated via dart-defines:
/// `CLOUD_R2_ACCOUNT_ID`, `CLOUD_R2_ACCESS_KEY_ID`, `CLOUD_R2_SECRET_ACCESS_KEY`,
/// optional `CLOUD_R2_BUCKET` (default `notis-pages`).
class R2CloudStore implements CloudStore {
  R2CloudStore({
    required this.uid,
    String? accountId,
    String? accessKeyId,
    String? secretAccessKey,
    String? bucket,
  }) : accountId = accountId ??
           const String.fromEnvironment('CLOUD_R2_ACCOUNT_ID'),
       accessKeyId = accessKeyId ??
           const String.fromEnvironment('CLOUD_R2_ACCESS_KEY_ID'),
       secretAccessKey = secretAccessKey ??
           const String.fromEnvironment('CLOUD_R2_SECRET_ACCESS_KEY'),
       bucket = bucket ??
           const String.fromEnvironment(
             'CLOUD_R2_BUCKET',
             defaultValue: 'notis-pages',
           );

  final String uid;
  final String accountId;
  final String accessKeyId;
  final String secretAccessKey;
  final String bucket;

  static const _region = 'auto';

  Uri _uri(String key) {
    final object = '$uid/$key';
    return Uri.https(
      '$accountId.r2.cloudflarestorage.com',
      '/$bucket/$object',
    );
  }

  @override
  Future<void> put(
    String key,
    Uint8List bytes, {
    String? contentType,
  }) async {
    final uri = _uri(key);
    final headers = _sign(
      method: 'PUT',
      uri: uri,
      payload: bytes,
      contentType: contentType ?? 'application/octet-stream',
    );
    final client = HttpClient();
    try {
      final request = await client.putUrl(uri);
      headers.forEach(request.headers.set);
      request.add(bytes);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode >= 300) {
        throw HttpException('R2 PUT ${response.statusCode} for $key');
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    final uri = _uri(key);
    final headers = _sign(method: 'GET', uri: uri, payload: Uint8List(0));
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);
      final response = await request.close();
      if (response.statusCode == 404) {
        await response.drain<void>();
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      if (response.statusCode >= 300) {
        throw HttpException('R2 GET ${response.statusCode} for $key');
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> delete(String key) async {
    final uri = _uri(key);
    final headers = _sign(method: 'DELETE', uri: uri, payload: Uint8List(0));
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(uri);
      headers.forEach(request.headers.set);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode == 404) return;
      if (response.statusCode >= 300) {
        throw HttpException('R2 DELETE ${response.statusCode} for $key');
      }
    } finally {
      client.close(force: true);
    }
  }

  Map<String, String> _sign({
    required String method,
    required Uri uri,
    required Uint8List payload,
    String? contentType,
  }) {
    final now = DateTime.now().toUtc();
    final dateStamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final amzDate =
        '${dateStamp}T'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}Z';
    final payloadHash = sha256.convert(payload).toString();
    final headers = <String, String>{
      'host': uri.host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'content-type': ?contentType,
    };
    final signedNames = headers.keys.toList()..sort();
    final canonicalHeaders = [
      for (final name in signedNames) '${name.toLowerCase()}:${headers[name]}\n',
    ].join();
    final signedHeaders = signedNames.join(';');
    final canonical =
        '$method\n${uri.path}\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
    final canonicalHash = sha256.convert(utf8.encode(canonical)).toString();
    final scope = '$dateStamp/$_region/s3/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$scope\n$canonicalHash';
    final signingKey = _signingKey(dateStamp);
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();
    headers['authorization'] =
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$scope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';
    return headers;
  }

  List<int> _signingKey(String dateStamp) {
    List<int> hmac(List<int> key, String data) =>
        Hmac(sha256, key).convert(utf8.encode(data)).bytes;
    final kDate = hmac(utf8.encode('AWS4$secretAccessKey'), dateStamp);
    final kRegion = hmac(kDate, _region);
    final kService = hmac(kRegion, 's3');
    return hmac(kService, 'aws4_request');
  }
}
