import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/audit_goal_totals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late AuditGoalTotalsUseCase usecase;
  late MockGoalContributionRepository mockRepository;

  setUp(() {
    mockRepository = MockGoalContributionRepository();
    usecase = AuditGoalTotalsUseCase(mockRepository);
  });

  test('should call auditGoalTotals on repository', () async {
    // Arrange
    when(
      () => mockRepository.auditGoalTotals(),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.auditGoalTotals()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
