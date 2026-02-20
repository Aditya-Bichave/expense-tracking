import 'dart:async';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Typed mocks
class MockPostgrestFilterBuilderListMap extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class MockPostgrestTransformBuilderListMap extends Mock
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {}

class MockPostgrestTransformBuilderMap extends Mock
    implements PostgrestTransformBuilder<Map<String, dynamic>> {}

// Fakes that are awaitable
class FakePostgrestFilterBuilderVoid extends Fake
    implements PostgrestFilterBuilder<void> {
  @override
  Future<S> then<S>(
    FutureOr<S> Function(void value) onValue, {
    Function? onError,
  }) async {
    return onValue(null);
  }
}

class FakePostgrestTransformBuilderMap extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> _result;
  FakePostgrestTransformBuilderMap(this._result);
  @override
  Future<S> then<S>(
    FutureOr<S> Function(Map<String, dynamic> value) onValue, {
    Function? onError,
  }) async {
    return onValue(_result);
  }
}

class FakePostgrestFilterBuilderListMap extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _result;
  FakePostgrestFilterBuilderListMap(this._result);
  @override
  Future<S> then<S>(
    FutureOr<S> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue(_result);
  }
}

void main() {
  late GroupExpensesRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  late MockPostgrestFilterBuilderListMap mockFilterBuilder;
  late MockPostgrestTransformBuilderListMap mockTransformBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilderListMap();
    mockTransformBuilder = MockPostgrestTransformBuilderListMap();

    dataSource = GroupExpensesRemoteDataSourceImpl(mockClient);

    // Use thenAnswer to avoid potential issues if SupabaseQueryBuilder is considered awaitable
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
  });

  final tExpense = GroupExpenseModel(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner',
    amount: 100,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27),
    createdAt: DateTime(2023, 10, 27),
    updatedAt: DateTime(2023, 10, 27),
    payers: [ExpensePayerModel(userId: 'u1', amount: 50)],
    splits: [
      ExpenseSplitModel(userId: 'u1', amount: 50, splitTypeValue: 'equal'),
    ],
  );

  group('createExpense', () {
    test('should insert expense, payers, and splits', () async {
      when(
        () => mockQueryBuilder.insert(any()),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        () => mockFilterBuilder.select(),
      ).thenAnswer((_) => mockTransformBuilder);
      when(
        () => mockTransformBuilder.single(),
      ).thenAnswer((_) => FakePostgrestTransformBuilderMap({}));

      final mockPayersBuilder = MockSupabaseQueryBuilder();
      final mockSplitsBuilder = MockSupabaseQueryBuilder();

      // Need to distinguish calls to .from() based on arguments
      when(
        () => mockClient.from('expenses'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockClient.from('expense_payers'),
      ).thenAnswer((_) => mockPayersBuilder);
      when(
        () => mockClient.from('expense_splits'),
      ).thenAnswer((_) => mockSplitsBuilder);

      when(
        () => mockPayersBuilder.insert(any()),
      ).thenAnswer((_) => FakePostgrestFilterBuilderVoid());
      when(
        () => mockSplitsBuilder.insert(any()),
      ).thenAnswer((_) => FakePostgrestFilterBuilderVoid());

      await dataSource.createExpense(tExpense);

      verify(() => mockClient.from('expenses')).called(1);
      verify(() => mockQueryBuilder.insert(any())).called(1);

      verify(() => mockClient.from('expense_payers')).called(1);
      verify(() => mockPayersBuilder.insert(any())).called(1);

      verify(() => mockClient.from('expense_splits')).called(1);
      verify(() => mockSplitsBuilder.insert(any())).called(1);
    });
  });

  group('getExpenses', () {
    test(
      'should return list of expenses with payers and splits mapped correctly',
      () async {
        final mockFilterBuilderList = MockPostgrestFilterBuilderListMap();

        when(
          () => mockClient.from('expenses'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.select(any()),
        ).thenAnswer((_) => mockFilterBuilderList);
        when(() => mockFilterBuilderList.eq(any(), any())).thenAnswer(
          (_) => FakePostgrestFilterBuilderListMap([
            {
              'id': '1',
              'group_id': 'g1',
              'created_by': 'c1',
              'title': 'Dinner',
              'amount': 100.0,
              'currency': 'USD',
              'occurred_at': '2023-10-27T00:00:00.000',
              'created_at': '2023-10-27T00:00:00.000',
              'updated_at': '2023-10-27T00:00:00.000',
              'expense_payers': [
                {'payer_user_id': 'u1', 'amount': 50.0},
              ],
              'expense_splits': [
                {'user_id': 'u1', 'amount': 50.0, 'split_type': 'equal'},
              ],
            },
          ]),
        );

        final result = await dataSource.getExpenses('g1');

        expect(result.length, 1);
        expect(result.first.id, '1');
        expect(result.first.payers.length, 1);
        expect(result.first.splits.length, 1);
      },
    );
  });
}
