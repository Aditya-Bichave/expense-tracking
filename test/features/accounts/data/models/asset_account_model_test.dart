import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tAccount = AssetAccount(
    id: '1',
    name: 'Main Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1200,
  );

  final tAccountModel = AssetAccountModel(
    id: '1',
    name: 'Main Bank',
    typeIndex: AssetType.bank.index,
    initialBalance: 1000,
  );

  group('AssetAccountModel', () {
    test(
      'toEntity should return valid entity with provided currentBalance',
      () {
        final result = tAccountModel.toEntity(1200);
        expect(result, tAccount);
      },
    );

    test('fromEntity should return valid model', () {
      final result = AssetAccountModel.fromEntity(tAccount);
      expect(result.id, tAccountModel.id);
      expect(result.typeIndex, tAccountModel.typeIndex);
    });
  });
}
