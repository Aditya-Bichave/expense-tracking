import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockUserHistoryRepository extends Mock implements UserHistoryRepository {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late SaveUserCategorizationHistoryUseCase usecase;
  late MockUserHistoryRepository mockRepository;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      UserHistoryRule(
        id: '',
        ruleType: RuleType.merchant,
        matcher: '',
        assignedCategoryId: '',
        timestamp: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockUserHistoryRepository();
    mockUuid = MockUuid();
    usecase = SaveUserCategorizationHistoryUseCase(mockRepository, mockUuid);
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Test Category',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  test('should save merchant rule when merchantId is provided', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('rule1');
    when(() => mockRepository.saveRule(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final params = SaveUserCategorizationHistoryParams(
      transactionData: const TransactionMatchData(
        merchantId: 'merch1',
        description: 'Test Desc',
      ),
      selectedCategory: tCategory,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Right(null));
    final captured =
        verify(() => mockRepository.saveRule(captureAny())).captured.single
            as UserHistoryRule;
    expect(captured.ruleType, RuleType.merchant);
    expect(captured.matcher, 'merch1');
    expect(captured.assignedCategoryId, 'cat1');
  });

  test('should save description rule when merchantId is missing', () async {
    // Arrange
    when(() => mockUuid.v4()).thenReturn('rule2');
    when(() => mockRepository.saveRule(any())).thenAnswer(
      (_) async => const Right(null),
    );

    final params = SaveUserCategorizationHistoryParams(
      transactionData: const TransactionMatchData(
        merchantId: null,
        description: 'Test Desc ',
      ),
      selectedCategory: tCategory,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Right(null));
    final captured =
        verify(() => mockRepository.saveRule(captureAny())).captured.single
            as UserHistoryRule;
    expect(captured.ruleType, RuleType.description);
    expect(captured.matcher, 'Test Desc'); // Trimmed
    expect(captured.assignedCategoryId, 'cat1');
  });
}
