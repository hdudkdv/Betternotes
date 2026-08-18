import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HMAC-SHA256 keystream + MAC. The wrapping key lives in the owner's
/// Firestore doc so another account on this device cannot open the blob.
abstract final class NotebookCrypto {
  static String encrypt(String plaintext, Uint8List key) {
    final iv = Uint8List(16);
    final rng = Random.secure();
    for (var i = 0; i < iv.length; i++) {
      iv[i] = rng.nextInt(256);
    }
    final data = Uint8List.fromList(utf8.encode(plaintext));
    final cipher = Uint8List(data.length);
    _xor(key, iv, data, cipher);
    final mac = Hmac(sha256, key).convert([...iv, ...cipher]).bytes;
    return base64Encode([...iv, ...mac, ...cipher]);
  }

  static String decrypt(String blob, Uint8List key) {
    final all = base64Decode(blob);
    if (all.length < 48) {
      throw const FormatException('locked notebook blob is truncated');
    }
    final iv = all.sublist(0, 16);
    final mac = all.sublist(16, 48);
    final cipher = all.sublist(48);
    final expected = Hmac(sha256, key).convert([...iv, ...cipher]).bytes;
    if (!_constantEquals(mac, expected)) {
      throw const FormatException('locked notebook blob failed verification');
    }
    final plain = Uint8List(cipher.length);
    _xor(key, iv, cipher, plain);
    return utf8.decode(plain);
  }

  static void _xor(Uint8List key, Uint8List iv, Uint8List input, Uint8List out) {
    var offset = 0;
    var counter = 0;
    while (offset < input.length) {
      final block = Hmac(sha256, key).convert([...iv, counter >> 24, counter >> 16, counter >> 8, counter]).bytes;
      counter++;
      for (var i = 0; i < block.length && offset < input.length; i++, offset++) {
        out[offset] = input[offset] ^ block[i];
      }
    }
  }

  static bool _constantEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
