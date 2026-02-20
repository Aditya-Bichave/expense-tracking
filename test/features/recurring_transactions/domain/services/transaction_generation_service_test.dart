import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/services/transaction_generation_service.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/generate_transactions_on_launch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGenerateTransactionsOnLaunch extends Mock
    implements GenerateTransactionsOnLaunch {}

void main() {
  late TransactionGenerationService service;
  late MockGenerateTransactionsOnLaunch mockUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockUseCase = MockGenerateTransactionsOnLaunch();
    service = TransactionGenerationService(mockUseCase);
  });

  test('run calls generateTransactionsOnLaunch', () async {
    when(() => mockUseCase(any())).thenAnswer((_) async => const Right(null));

    await service.run();

    verify(() => mockUseCase(any())).called(1);
  });
}
