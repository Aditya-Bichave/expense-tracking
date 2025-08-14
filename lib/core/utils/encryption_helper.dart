import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static const _saltLength = 16;

  static Map<String, String> encryptString(String plainText, String password) {
    final salt = _generateSalt();
    final key = _deriveKey(password, salt);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return {
      'salt': base64Encode(salt),
      'iv': iv.base64,
      'cipher': encrypted.base64,
    };
  }

  static String decryptString(Map<String, dynamic> payload, String password) {
    final salt = base64Decode(payload['salt'] as String);
    final key = _deriveKey(password, salt);
    final iv = encrypt.IV.fromBase64(payload['iv'] as String);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(payload['cipher'] as String, iv: iv);
  }

  static encrypt.Key _deriveKey(String password, List<int> salt) {
    final data = utf8.encode(password) + salt;
    final hash = sha256.convert(data).bytes;
    return encrypt.Key(Uint8List.fromList(hash));
  }

  static List<int> _generateSalt() {
    final rand = Random.secure();
    return List<int>.generate(_saltLength, (_) => rand.nextInt(256));
  }
}
