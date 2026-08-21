import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockOutboxRepository mockOutboxRepository;

  setUpAll(() {
    registerFallbackValue(
      ExpenseModel(
        id: '1',
        title: 'f',
        amount: 1,
        date: DateTime.now(),
        accountId: 'a',
      ),
    );
    registerFallbackValue(
      SyncMutationModel(
        id: '1',
        table: 'expenses',
        operation: OpType.update,
        payload: const {},
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockExpenseLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockOutboxRepository = MockOutboxRepository();

    repository = ExpenseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
      supabaseClient: mockSupabaseClient,
      outboxRepository: mockOutboxRepository,
    );
  });

  final tDate = DateTime(2026, 4, 1);
  final tModel = ExpenseModel(
    id: 'exp1',
    title: 'Lunch',
    amount: 15.0,
    date: tDate,
    accountId: 'acc1',
  );

  group('Soft Delete - ExpenseRepository', () {
    test(
      'deleteExpense sets deletedAt and enqueues update mutation instead of removing row',
      () async {
        when(
          () => mockLocalDataSource.getExpenseById('exp1'),
        ).thenAnswer((_) async => tModel);
        when(
          () => mockLocalDataSource.updateExpense(any()),
        ).thenAnswer((_) async => tModel);
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.deleteExpense('exp1');

        expect(result.isRight(), true);
        final capturedModel =
            verify(
                  () => mockLocalDataSource.updateExpense(captureAny()),
                ).captured.single
                as ExpenseModel;
        expect(capturedModel.deletedAt, isNotNull);
        verify(() => mockOutboxRepository.add(any())).called(1);
      },
    );

    test('getExpenses excludes soft-deleted items', () async {
      when(
        () => mockLocalDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.getExpenses();

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.getExpenses()).called(1);
    });

    test(
      'restoreExpense clears deletedAt and enqueues update mutation',
      () async {
        final deletedModel = ExpenseModel(
          id: 'exp1',
          title: 'Lunch',
          amount: 15.0,
          date: tDate,
          accountId: 'acc1',
          deletedAt: DateTime.now(),
        );

        when(
          () => mockLocalDataSource.getExpenseById('exp1'),
        ).thenAnswer((_) async => deletedModel);
        when(
          () => mockLocalDataSource.updateExpense(any()),
        ).thenAnswer((_) async => tModel);
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.restoreExpense('exp1');

        expect(result.isRight(), true);
        final capturedModel =
            verify(
                  () => mockLocalDataSource.updateExpense(captureAny()),
                ).captured.single
                as ExpenseModel;
        expect(capturedModel.deletedAt, isNull);
        verify(() => mockOutboxRepository.add(any())).called(1);
      },
    );

    test(
      'purgeExpense permanently removes row and enqueues delete mutation',
      () async {
        when(
          () => mockLocalDataSource.deleteExpense('exp1'),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.purgeExpense('exp1');

        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.deleteExpense('exp1')).called(1);
        verify(() => mockOutboxRepository.add(any())).called(1);
      },
    );

    test(
      'purgeExpiredExpenses purges items deleted > 30 days before injected now',
      () async {
        final now = DateTime(2026, 4, 1);
        final oldDeleted = ExpenseModel(
          id: 'exp1',
          title: 'Old',
          amount: 10.0,
          date: now.subtract(const Duration(days: 40)),
          accountId: 'acc1',
          deletedAt: now.subtract(const Duration(days: 35)),
        );
        final recentDeleted = ExpenseModel(
          id: 'exp2',
          title: 'Recent',
          amount: 20.0,
          date: now.subtract(const Duration(days: 10)),
          accountId: 'acc1',
          deletedAt: now.subtract(const Duration(days: 5)),
        );

        when(
          () => mockLocalDataSource.getAllRawExpenses(),
        ).thenAnswer((_) async => [oldDeleted, recentDeleted]);
        when(
          () => mockLocalDataSource.deleteExpense('exp1'),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.purgeExpiredExpenses(now);

        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.deleteExpense('exp1')).called(1);
        verifyNever(() => mockLocalDataSource.deleteExpense('exp2'));
      },
    );
  });
}
