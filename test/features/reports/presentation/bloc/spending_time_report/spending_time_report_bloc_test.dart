import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSpendingTimeReportUseCase extends Mock
    implements GetSpendingTimeReportUseCase {}

class MockReportFilterBloc extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late SpendingTimeReportBloc bloc;
  late MockGetSpendingTimeReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(
      GetSpendingTimeReportParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        granularity: TimeSeriesGranularity.daily,
        compareToPrevious: false,
      ),
    );
    registerFallbackValue(TimeSeriesGranularity.daily);
  });

  setUp(() {
    mockUseCase = MockGetSpendingTimeReportUseCase();
    mockFilterBloc = MockReportFilterBloc();

    // Default filter state
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final tReportData = SpendingTimeReportData(
    spendingData: const [],
    granularity: TimeSeriesGranularity.daily,
  );

  blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
    'emits [Loading, Loaded] when initialized and use case succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tReportData));
      return SpendingTimeReportBloc(
        getSpendingTimeReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    // The LoadSpendingTimeReport event is added in constructor
    expect: () => [
      isA<SpendingTimeReportLoading>()
          .having((s) => s.granularity, 'granularity', TimeSeriesGranularity.daily)
          .having((s) => s.compareToPrevious, 'compare', false),
      isA<SpendingTimeReportLoaded>()
          .having((s) => s.reportData, 'data', tReportData)
          .having((s) => s.showComparison, 'compare', false),
    ],
  );

  blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
    'emits [Loading, Error] when use case fails',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return SpendingTimeReportBloc(
        getSpendingTimeReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    expect: () => [
      isA<SpendingTimeReportLoading>(),
      isA<SpendingTimeReportError>().having((s) => s.message, 'message', 'Error'),
    ],
  );

  blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
    'emits [Loading, Loaded] with new granularity when ChangeGranularity is added',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tReportData));
      return SpendingTimeReportBloc(
        getSpendingTimeReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    skip: 2, // Skip initial loading/loaded
    act: (bloc) => bloc.add(const ChangeGranularity(TimeSeriesGranularity.weekly)),
    expect: () => [
      isA<SpendingTimeReportLoading>()
          .having((s) => s.granularity, 'granularity', TimeSeriesGranularity.weekly),
      isA<SpendingTimeReportLoaded>(),
    ],
  );
}
