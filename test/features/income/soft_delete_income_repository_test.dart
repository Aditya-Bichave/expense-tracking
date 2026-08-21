import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';

class MockIncomeLocalDataSource extends Mock implements IncomeLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

void main() {
  late IncomeRepositoryImpl repository;
  late MockIncomeLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockOutboxRepository mockOutboxRepository;

  setUpAll(() {
    registerFallbackValue(
      IncomeModel(
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
        table: 'incomes',
        operation: OpType.update,
        payload: const {},
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockIncomeLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    mockOutboxRepository = MockOutboxRepository();

    repository = IncomeRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
      outboxRepository: mockOutboxRepository,
    );
  });

  final tDate = DateTime(2026, 4, 1);
  final tModel = IncomeModel(
    id: 'inc1',
    title: 'Salary',
    amount: 1000.0,
    date: tDate,
    accountId: 'acc1',
  );

  group('Soft Delete - IncomeRepository', () {
    test('deleteIncome sets deletedAt and enqueues update mutation', () async {
      when(
        () => mockLocalDataSource.getIncomeById('inc1'),
      ).thenAnswer((_) async => tModel);
      when(
        () => mockLocalDataSource.updateIncome(any()),
      ).thenAnswer((_) async => tModel);
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

      final result = await repository.deleteIncome('inc1');

      expect(result.isRight(), true);
      final capturedModel =
          verify(
                () => mockLocalDataSource.updateIncome(captureAny()),
              ).captured.single
              as IncomeModel;
      expect(capturedModel.deletedAt, isNotNull);
      verify(() => mockOutboxRepository.add(any())).called(1);
    });

    test('getIncomes excludes soft-deleted items', () async {
      when(
        () => mockLocalDataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);

      final result = await repository.getIncomes();

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.getIncomes()).called(1);
    });

    test(
      'restoreIncome clears deletedAt and enqueues update mutation',
      () async {
        final deletedModel = IncomeModel(
          id: 'inc1',
          title: 'Salary',
          amount: 1000.0,
          date: tDate,
          accountId: 'acc1',
          deletedAt: DateTime.now(),
        );

        when(
          () => mockLocalDataSource.getIncomeById('inc1'),
        ).thenAnswer((_) async => deletedModel);
        when(
          () => mockLocalDataSource.updateIncome(any()),
        ).thenAnswer((_) async => tModel);
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.restoreIncome('inc1');

        expect(result.isRight(), true);
        final capturedModel =
            verify(
                  () => mockLocalDataSource.updateIncome(captureAny()),
                ).captured.single
                as IncomeModel;
        expect(capturedModel.deletedAt, isNull);
        verify(() => mockOutboxRepository.add(any())).called(1);
      },
    );

    test(
      'purgeIncome removes row permanently and enqueues delete mutation',
      () async {
        when(
          () => mockLocalDataSource.deleteIncome('inc1'),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.purgeIncome('inc1');

        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.deleteIncome('inc1')).called(1);
        verify(() => mockOutboxRepository.add(any())).called(1);
      },
    );

    test(
      'purgeExpiredIncomes purges items deleted > 30 days before injected now',
      () async {
        final now = DateTime(2026, 4, 1);
        final oldDeleted = IncomeModel(
          id: 'inc1',
          title: 'Old',
          amount: 10.0,
          date: now.subtract(const Duration(days: 40)),
          accountId: 'acc1',
          deletedAt: now.subtract(const Duration(days: 35)),
        );
        final recentDeleted = IncomeModel(
          id: 'inc2',
          title: 'Recent',
          amount: 20.0,
          date: now.subtract(const Duration(days: 10)),
          accountId: 'acc1',
          deletedAt: now.subtract(const Duration(days: 5)),
        );

        when(
          () => mockLocalDataSource.getAllRawIncomes(),
        ).thenAnswer((_) async => [oldDeleted, recentDeleted]);
        when(
          () => mockLocalDataSource.deleteIncome('inc1'),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});

        final result = await repository.purgeExpiredIncomes(now);

        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.deleteIncome('inc1')).called(1);
        verifyNever(() => mockLocalDataSource.deleteIncome('inc2'));
      },
    );
  });
}
