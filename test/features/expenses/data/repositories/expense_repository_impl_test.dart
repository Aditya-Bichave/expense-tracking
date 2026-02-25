import 'dart:async';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final T _value;
  FakePostgrestFilterBuilder(this._value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(_value));
  }
}

void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockSupabaseClient mockSupabaseClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockLocalDataSource = MockExpenseLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    mockSupabaseClient = MockSupabaseClient();
    repository = ExpenseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
      supabaseClient: mockSupabaseClient,
    );
  });

  group('createExpenseTransaction', () {
    final tExpense = Expense(
      id: 'temp-id',
      title: 'Dinner',
      amount: 100.00,
      date: DateTime.now(),
      accountId: 'acc1',
      groupId: 'grp1',
      createdBy: 'user1',
      currency: 'USD',
      payers: const [ExpensePayer(userId: 'user1', amountPaid: 100.00)],
      splits: const [
        ExpenseSplit(
          userId: 'user1',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 100.00,
        ),
      ],
    );

    test(
      'should call Supabase RPC and return updated expense on success',
      () async {
        // Arrange
        final fakeBuilder = FakePostgrestFilterBuilder<String>(
          'new-uuid',
        ); // Explicit type String

        // Match exactly on the function name, and any params
        when(
          () => mockSupabaseClient.rpc<String>(
            // Explicit generic
            'create_expense_transaction',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => fakeBuilder);

        // Act
        final result = await repository.createExpenseTransaction(tExpense);

        // Assert
        verify(
          () => mockSupabaseClient.rpc<String>(
            'create_expense_transaction',
            params: any(named: 'params'),
          ),
        ).called(1);

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should be Right but got $l'),
          (r) => expect(r.id, 'new-uuid'),
        );
      },
    );

    test('should return Failure when validation fails locally', () async {
      // Arrange - Invalid split (sum != total)
      final invalidExpense = tExpense.copyWith(
        amount: 100.00,
        splits: const [
          ExpenseSplit(
            userId: 'user1',
            shareType: SplitType.equal,
            shareValue: 1,
            computedAmount: 50.00,
          ),
        ],
      );

      // Act
      final result = await repository.createExpenseTransaction(invalidExpense);

      // Assert
      expect(result.isLeft(), true);
      verifyNever(
        () => mockSupabaseClient.rpc(any(), params: any(named: 'params')),
      );
    });

    test('should return Failure when RPC fails', () async {
      // Arrange
      when(
        () => mockSupabaseClient.rpc<String>(
          'create_expense_transaction',
          params: any(named: 'params'),
        ),
      ).thenThrow(const PostgrestException(message: 'RPC Error'));

      // Act
      final result = await repository.createExpenseTransaction(tExpense);

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
