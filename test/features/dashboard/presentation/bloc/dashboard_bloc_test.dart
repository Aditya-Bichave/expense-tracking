import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetFinancialOverviewUseCase extends Mock
    implements GetFinancialOverviewUseCase {}

void main() {
  late DashboardBloc bloc;
  late MockGetFinancialOverviewUseCase mockUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(
      GetFinancialOverviewParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockUseCase = MockGetFinancialOverviewUseCase();
    dataChangeController = StreamController<DataChangedEvent>();
  });

  tearDown(() {
    dataChangeController.close();
  });

  final tOverview = FinancialOverview(
    totalIncome: 100,
    totalExpenses: 50,
    netFlow: 50,
    overallBalance: 100,
    accounts: const [],
    accountBalances: const {},
    activeBudgetsSummary: const [],
    activeGoalsSummary: const [],
    recentSpendingSparkline: const [],
    recentContributionSparkline: const [],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emits [Loading, Loaded] when LoadDashboard is added and succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tOverview));
      return DashboardBloc(
        getFinancialOverviewUseCase: mockUseCase,
        dataChangeStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(const LoadDashboard()),
    expect: () => [
      const DashboardLoading(),
      DashboardLoaded(tOverview),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emits [Loading, Error] when LoadDashboard fails',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return DashboardBloc(
        getFinancialOverviewUseCase: mockUseCase,
        dataChangeStream: dataChangeController.stream,
      );
    },
    act: (bloc) => bloc.add(const LoadDashboard()),
    expect: () => [
      const DashboardLoading(),
      isA<DashboardError>(), // We can check message if needed
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'reloads when relevant DataChangedEvent is received',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tOverview));
      return DashboardBloc(
        getFinancialOverviewUseCase: mockUseCase,
        dataChangeStream: dataChangeController.stream,
      );
    },
    act: (bloc) async {
      bloc.add(const LoadDashboard());
      await Future.delayed(Duration.zero); // Wait for first load
      dataChangeController.add(const DataChangedEvent(type: DataChangeType.expense, reason: DataChangeReason.added));
    },
    // We expect Loading -> Loaded (initial), then Loading (reloading) -> Loaded (reload)
    // But since act adds LoadDashboard, we get the first two.
    // Then adding to stream triggers _DataChanged -> LoadDashboard(force=true)
    // So we get another Loading -> Loaded.
    expect: () => [
      const DashboardLoading(isReloading: false),
      DashboardLoaded(tOverview),
      const DashboardLoading(isReloading: true),
      DashboardLoaded(tOverview),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'resets state when System Reset event is received',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tOverview));
      return DashboardBloc(
        getFinancialOverviewUseCase: mockUseCase,
        dataChangeStream: dataChangeController.stream,
      );
    },
    act: (bloc) {
      dataChangeController.add(const DataChangedEvent(type: DataChangeType.system, reason: DataChangeReason.reset));
    },
    expect: () => [
      DashboardInitial(),
      const DashboardLoading(),
      DashboardLoaded(tOverview),
    ],
  );
}
