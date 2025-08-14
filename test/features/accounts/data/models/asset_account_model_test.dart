import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toEntity uses typeIndex when valid', () {
    final model = AssetAccountModel(
      id: '1',
      name: 'Bank',
      typeIndex: AssetType.bank.index,
      initialBalance: 0,
    );

    final entity = model.toEntity(100);

    expect(entity.type, AssetType.bank);
  });

  test('toEntity defaults to other on invalid typeIndex', () {
    final model = AssetAccountModel(
      id: '1',
      name: 'Unknown',
      typeIndex: 999,
      initialBalance: 0,
    );

    final entity = model.toEntity(50);

    expect(entity.type, AssetType.other);
  });
}
