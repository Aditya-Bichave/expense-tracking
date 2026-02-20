import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetAccount', () {
    test('supports value equality', () {
      final a1 = AssetAccount(
        id: '1',
        name: 'A',
        type: AssetType.bank,
        currentBalance: 0,
      );
      final a2 = AssetAccount(
        id: '1',
        name: 'A',
        type: AssetType.bank,
        currentBalance: 0,
      );
      expect(a1, equals(a2));
    });

    test('typeName returns correct string', () {
      expect(
        const AssetAccount(
          id: '1',
          name: 'A',
          type: AssetType.bank,
          currentBalance: 0,
        ).typeName,
        'Bank',
      );
      expect(
        const AssetAccount(
          id: '1',
          name: 'A',
          type: AssetType.cash,
          currentBalance: 0,
        ).typeName,
        'Cash',
      );
    });

    test('iconData returns correct icon', () {
      expect(
        const AssetAccount(
          id: '1',
          name: 'A',
          type: AssetType.bank,
          currentBalance: 0,
        ).iconData,
        Icons.account_balance,
      );
    });
  });
}
