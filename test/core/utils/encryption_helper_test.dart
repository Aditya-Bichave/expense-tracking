import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptionHelper', () {
    test('encrypt and decrypt round trip', () {
      const password = 'my-secret-password';
      const plainText = 'Hello, World!';

      final encrypted = EncryptionHelper.encryptString(plainText, password);
      expect(encrypted['salt'], isNotNull);
      expect(encrypted['iv'], isNotNull);
      expect(encrypted['cipher'], isNotNull);
      expect(encrypted['mac'], isNotNull);

      final decrypted = EncryptionHelper.decryptString(encrypted, password);
      expect(decrypted, plainText);
    });

    test('decrypt with wrong password throws', () {
      const password = 'correct-password';
      const wrongPassword = 'wrong-password';
      const plainText = 'Hello';

      final encrypted = EncryptionHelper.encryptString(plainText, password);

      // Decryption might fail at AES decryption (padding) OR HMAC check.
      // The helper throws FormatException for HMAC mismatch if present, or potentially other errors if AES padding is invalid.
      // But based on implementation:
      // `encrypter.decrypt64` might throw if key is wrong before MAC check if padding is messed up.
      // But if MAC check fails, it throws FormatException.

      // Let's expect generic Exception or Error.
      expect(
        () => EncryptionHelper.decryptString(encrypted, wrongPassword),
        throwsA(anything),
      );
    });
  });
}
