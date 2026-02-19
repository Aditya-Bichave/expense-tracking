import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/categories/data/repositories/user_history_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserHistoryLocalDataSource extends Mock
    implements UserHistoryLocalDataSource {}

void main() {
  late UserHistoryRepositoryImpl repository;
  late MockUserHistoryLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(
      UserHistoryRuleModel(
        ruleId: '',
        ruleType: RuleType.merchant,
        matcher: '',
        assignedCategoryId: '',
        timestamp: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockDataSource = MockUserHistoryLocalDataSource();
    repository = UserHistoryRepositoryImpl(localDataSource: mockDataSource);
  });

  final tDate = DateTime(2023, 1, 1);
  final tRule = UserHistoryRule(
    id: '1',
    ruleType: RuleType.merchant,
    matcher: 'uber',
    assignedCategoryId: 'transport',
    timestamp: tDate,
  );
  final tRuleModel = UserHistoryRuleModel.fromEntity(tRule);

  test('should return rule from dataSource when found', () async {
    // Arrange
    when(() => mockDataSource.findRule(RuleType.merchant.name, 'uber'))
        .thenAnswer((_) async => tRuleModel);

    // Act
    final result = await repository.findRule(RuleType.merchant, 'uber');

    // Assert
    expect(result, Right(tRule));
    verify(() => mockDataSource.findRule(RuleType.merchant.name, 'uber')).called(1);
  });

  test('should save rule to dataSource', () async {
    // Arrange
    when(() => mockDataSource.findRule(any(), any()))
        .thenAnswer((_) async => null); // No existing rule
    when(() => mockDataSource.saveRule(any()))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.saveRule(tRule);

    // Assert
    expect(result, const Right(null));
    verify(() => mockDataSource.saveRule(tRuleModel)).called(1);
  });
}
