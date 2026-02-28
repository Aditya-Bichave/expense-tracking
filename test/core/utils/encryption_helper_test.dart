import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptionHelper', () {
    const password = 'super_secret_password';
    const plainText = 'This is a secret message!';

    test('encryptString returns valid map keys', () {
      final result = EncryptionHelper.encryptString(plainText, password);
      expect(result.keys, containsAll(['salt', 'iv', 'cipher', 'mac']));
      expect(result['salt'], isNotEmpty);
      expect(result['iv'], isNotEmpty);
      expect(result['cipher'], isNotEmpty);
      expect(result['mac'], isNotEmpty);
    });

    test(
      'encryptString produces different outputs for same input (random salt/iv)',
      () {
        final result1 = EncryptionHelper.encryptString(plainText, password);
        final result2 = EncryptionHelper.encryptString(plainText, password);

        expect(result1['cipher'], isNot(equals(result2['cipher'])));
        expect(result1['iv'], isNot(equals(result2['iv'])));
        expect(result1['salt'], isNot(equals(result2['salt'])));
      },
    );

    test('decryptString decrypts correctly', () {
      final encrypted = EncryptionHelper.encryptString(plainText, password);
      final decrypted = EncryptionHelper.decryptString(encrypted, password);
      expect(decrypted, plainText);
    });

    test('decryptString throws on wrong password', () {
      final encrypted = EncryptionHelper.encryptString(plainText, password);

      expect(
        () => EncryptionHelper.decryptString(encrypted, 'wrong_password'),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    });

    test('decryptString throws on tampered cipher', () {
      final encrypted = EncryptionHelper.encryptString(plainText, password);
      // Tamper with cipher
      final tampered = Map<String, dynamic>.from(encrypted);
      tampered['cipher'] = 'AAAA${(tampered['cipher'] as String).substring(4)}';

      // Depending on implementation, this might throw Mac validation error or padding error
      expect(
        () => EncryptionHelper.decryptString(tampered, password),
        throwsA(isA<Exception>()),
      );
    });
  });
}
