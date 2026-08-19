import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';

class MockIncomeLocalDataSource extends Mock implements IncomeLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class _FakeIncomeModel extends Fake implements IncomeModel {}

void main() {
  late MockIncomeLocalDataSource dataSource;
  late MockCategoryRepository categoryRepository;
  late IncomeRepositoryImpl repository;

  const salaryCategory = Category(
    id: 'c-salary',
    name: 'Salary',
    iconName: 'work',
    colorHex: '#00FF00',
    type: CategoryType.income,
    isCustom: false,
  );

  IncomeModel model({
    String id = 'i1',
    String title = 'Paycheck',
    double amount = 1000,
    String? categoryId,
    String accountId = 'a1',
    String? notes,
  }) => IncomeModel(
    id: id,
    title: title,
    amount: amount,
    date: DateTime(2024, 1, 1),
    categoryId: categoryId,
    accountId: accountId,
    notes: notes,
  );

  void stubGetIncomes(List<IncomeModel> models) {
    when(
      () => dataSource.getIncomes(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => models);
  }

  setUpAll(() {
    registerFallbackValue(_FakeIncomeModel());
  });

  setUp(() {
    dataSource = MockIncomeLocalDataSource();
    categoryRepository = MockCategoryRepository();
    repository = IncomeRepositoryImpl(
      localDataSource: dataSource,
      categoryRepository: categoryRepository,
    );

    // Hydration always consults the category repository, passing '' for an
    // uncategorized income, so a default "no category" answer is required.
    when(
      () => categoryRepository.getCategoryById(any()),
    ).thenAnswer((_) async => const Right<Failure, Category?>(null));
  });

  group('getIncomeById', () {
    test('returns null when nothing is stored under that id', () async {
      when(
        () => dataSource.getIncomeById('ghost'),
      ).thenAnswer((_) async => null);

      expect(rightOf(await repository.getIncomeById('ghost')), isNull);
    });

    test('returns the hydrated income when present', () async {
      when(
        () => dataSource.getIncomeById('i1'),
      ).thenAnswer((_) async => model(title: 'Bonus'));

      final result = await repository.getIncomeById('i1');

      expect(rightOf(result), isA<Income>());
      expect(rightOf(result)?.title, 'Bonus');
    });

    test('hydrates the category when the income has one', () async {
      when(
        () => dataSource.getIncomeById('i1'),
      ).thenAnswer((_) async => model(categoryId: 'c-salary'));
      when(
        () => categoryRepository.getCategoryById('c-salary'),
      ).thenAnswer((_) async => const Right(salaryCategory));

      final result = await repository.getIncomeById('i1');

      expect(rightOf(result)?.category?.name, 'Salary');
    });

    test('maps a thrown error to CacheFailure', () async {
      when(() => dataSource.getIncomeById('i1')).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getIncomeById('i1')),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Error getting income'),
        ),
      );
    });
  });

  group('getTotalIncomeForAccount', () {
    test('sums the amounts of the matching incomes', () async {
      stubGetIncomes([
        model(id: 'i1', amount: 1000),
        model(id: 'i2', amount: 250.5),
      ]);

      expect(rightOf(await repository.getTotalIncomeForAccount('a1')), 1250.5);
    });

    test('returns zero when the account has no income', () async {
      stubGetIncomes([]);

      expect(rightOf(await repository.getTotalIncomeForAccount('a1')), 0.0);
    });

    test('treats an empty account id as "no account filter"', () async {
      stubGetIncomes([]);

      await repository.getTotalIncomeForAccount('');

      verify(
        () => dataSource.getIncomes(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        ),
      ).called(1);
    });

    test('forwards the date range to the data source', () async {
      stubGetIncomes([]);
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      await repository.getTotalIncomeForAccount(
        'a1',
        startDate: start,
        endDate: end,
      );

      verify(
        () => dataSource.getIncomes(
          startDate: start,
          endDate: end,
          categoryId: null,
          accountId: 'a1',
        ),
      ).called(1);
    });

    test('propagates a data source failure', () async {
      when(
        () => dataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(const CacheFailure('income box closed'));

      expect(
        leftOf(await repository.getTotalIncomeForAccount('a1')),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'income box closed',
        ),
      );
    });
  });

  group('updateIncomeCategorization', () {
    test('returns CacheFailure when the income does not exist', () async {
      when(
        () => dataSource.getIncomeById('ghost'),
      ).thenAnswer((_) async => null);

      expect(
        leftOf(
          await repository.updateIncomeCategorization(
            'ghost',
            'c-salary',
            CategorizationStatus.categorized,
            1,
          ),
        ),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'Income not found.',
        ),
      );
    });

    test(
      'writes back the category, status, confidence and keeps notes',
      () async {
        when(
          () => dataSource.getIncomeById('i1'),
        ).thenAnswer((_) async => model(notes: 'monthly'));
        when(
          () => dataSource.updateIncome(any()),
        ).thenAnswer((i) async => i.positionalArguments.first as IncomeModel);

        final result = await repository.updateIncomeCategorization(
          'i1',
          'c-salary',
          CategorizationStatus.categorized,
          0.75,
        );

        expect(result.isRight(), isTrue);
        final written =
            verify(() => dataSource.updateIncome(captureAny())).captured.single
                as IncomeModel;
        expect(written.categoryId, 'c-salary');
        expect(
          written.categorizationStatusValue,
          CategorizationStatus.categorized.value,
        );
        expect(written.confidenceScoreValue, 0.75);
        expect(written.notes, 'monthly');
      },
    );

    test('propagates a CacheFailure from the write', () async {
      when(
        () => dataSource.getIncomeById('i1'),
      ).thenAnswer((_) async => model());
      when(
        () => dataSource.updateIncome(any()),
      ).thenThrow(const CacheFailure('locked'));

      expect(
        leftOf(
          await repository.updateIncomeCategorization(
            'i1',
            'c-salary',
            CategorizationStatus.categorized,
            1,
          ),
        ),
        isA<CacheFailure>().having((f) => f.message, 'message', 'locked'),
      );
    });

    test('wraps an unexpected write error as CacheFailure', () async {
      when(
        () => dataSource.getIncomeById('i1'),
      ).thenAnswer((_) async => model());
      when(() => dataSource.updateIncome(any())).thenThrow(StateError('x'));

      expect(
        leftOf(
          await repository.updateIncomeCategorization(
            'i1',
            null,
            CategorizationStatus.uncategorized,
            null,
          ),
        ).message,
        contains('Failed to update income categorization'),
      );
    });
  });

  group('reassignIncomesCategory', () {
    test('returns zero and writes nothing when nothing matches', () async {
      stubGetIncomes([model(id: 'i1', categoryId: 'other')]);

      expect(
        rightOf(await repository.reassignIncomesCategory('old', 'new')),
        0,
      );
      verifyNever(() => dataSource.updateIncome(any()));
    });

    test('rewrites every matching income and reports the count', () async {
      stubGetIncomes([
        model(id: 'i1', categoryId: 'old'),
        model(id: 'i2', categoryId: 'other'),
        model(id: 'i3', categoryId: 'old'),
      ]);
      when(
        () => dataSource.updateIncome(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as IncomeModel);

      final count = rightOf(
        await repository.reassignIncomesCategory('old', 'new'),
      );

      expect(count, 2);
      final written = verify(
        () => dataSource.updateIncome(captureAny()),
      ).captured.cast<IncomeModel>();
      expect(written.map((m) => m.id), ['i1', 'i3']);
      expect(written.every((m) => m.categoryId == 'new'), isTrue);
      expect(
        written.every(
          (m) =>
              m.categorizationStatusValue ==
              CategorizationStatus.categorized.value,
        ),
        isTrue,
      );
      // Reassignment is an explicit user action, so any prior ML confidence
      // score must be cleared.
      expect(written.every((m) => m.confidenceScoreValue == null), isTrue);
    });

    test('surfaces a failure from the read', () async {
      when(
        () => dataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.reassignIncomesCategory('old', 'new')),
        isA<CacheFailure>().having((f) => f.message, 'message', contains('io')),
      );
    });
  });
}
