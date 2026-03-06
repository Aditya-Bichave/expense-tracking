import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';

void main() {
  test('ExpenseModel copyWith logic includes revision', () {
    final model = ExpenseModel(
      id: '1',
      title: 'Title',
      amount: 100.0,
      date: DateTime.now(),
      accountId: 'acc1',
      clientGeneratedId: 'client1',
      revision: 1,
    );

    final entity = model.toEntity();
    expect(entity.clientGeneratedId, 'client1');
    expect(entity.revision, 1);

    final copiedEntity = entity.copyWith(
      revision: 2,
      clientGeneratedId: 'client2',
    );
    expect(copiedEntity.revision, 2);
    expect(copiedEntity.clientGeneratedId, 'client2');

    final copiedBack = ExpenseModel.fromEntity(copiedEntity);
    expect(copiedBack.revision, 2);
    expect(copiedBack.clientGeneratedId, 'client2');
  });
}
