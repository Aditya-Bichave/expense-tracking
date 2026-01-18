import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tAssetAccountModel = AssetAccountModel(
    id: '1',
    name: 'Test Account',
    typeIndex: 0,
    initialBalance: 100.0,
  );

  const tAssetAccount = AssetAccount(
    id: '1',
    name: 'Test Account',
    type: AssetType.bank, // Assuming 0 is bank (AssetType.values[0])
    initialBalance: 100.0,
    currentBalance: 200.0,
  );

  group('AssetAccountModel', () {
    test('should be a subclass of HiveObject', () {
      expect(tAssetAccountModel, isA<AssetAccountModel>());
    });

    test('fromEntity should return a valid model', () {
      final result = AssetAccountModel.fromEntity(tAssetAccount);
      expect(result.id, tAssetAccount.id);
      expect(result.name, tAssetAccount.name);
      expect(result.typeIndex, tAssetAccount.type.index);
      expect(result.initialBalance, tAssetAccount.initialBalance);
    });

    test('toEntity should return a valid entity', () {
      final result = tAssetAccountModel.toEntity(200.0);
      expect(result.id, tAssetAccountModel.id);
      expect(result.name, tAssetAccountModel.name);
      expect(result.type.index, tAssetAccountModel.typeIndex);
      expect(result.initialBalance, tAssetAccountModel.initialBalance);
      expect(result.currentBalance, 200.0);
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'id': '1',
        'name': 'Test Account',
        'typeIndex': 0,
        'initialBalance': 100.0,
      };
      final result = AssetAccountModel.fromJson(jsonMap);
      expect(result.id, '1');
      expect(result.name, 'Test Account');
      expect(result.typeIndex, 0);
      expect(result.initialBalance, 100.0);
    });

    test('toJson should return a JSON map containing proper data', () {
      final result = tAssetAccountModel.toJson();
      final expectedMap = {
        'id': '1',
        'name': 'Test Account',
        'typeIndex': 0,
        'initialBalance': 100.0,
      };
      expect(result, expectedMap);
    });
  });
}
