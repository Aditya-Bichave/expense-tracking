import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypt and decrypt round trip', () {
    const password = 'secret';
    const text = 'hello world';
    final payload = EncryptionHelper.encryptString(text, password);
    final decrypted = EncryptionHelper.decryptString(payload, password);
    expect(decrypted, text);
    expect(payload['cipher']!.contains(text), isFalse);
  });

  test('decrypt with wrong password throws', () {
    const password = 'secret';
    final payload = EncryptionHelper.encryptString('data', password);
    expect(
      () => EncryptionHelper.decryptString(payload, 'wrong'),
      throwsA(anything),
    );
  });
}
