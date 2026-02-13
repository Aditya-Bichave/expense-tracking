import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSpendingTimeReportUseCase extends Mock
    implements GetSpendingTimeReportUseCase {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late SpendingTimeReportBloc bloc;
  late MockGetSpendingTimeReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  final tReportData = SpendingTimeReportData(
    spendingData: const [],
    granularity: TimeSeriesGranularity.daily,
  );

  setUpAll(() {
    registerFallbackValue(GetSpendingTimeReportParams(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      granularity: TimeSeriesGranularity.daily,
      compareToPrevious: false,
    ));
  });

  setUp(() {
    mockUseCase = MockGetSpendingTimeReportUseCase();
    mockFilterBloc = MockReportFilterBloc();
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
  });

  group('LoadSpendingTimeReport', () {
    blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
      'emits [loading, loaded] on success',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tReportData));
        return SpendingTimeReportBloc(
          getSpendingTimeReportUseCase: mockUseCase,
          reportFilterBloc: mockFilterBloc,
        );
      },
      // Initial load triggered in constructor
      expect: () => [
        isA<SpendingTimeReportLoading>(),
        SpendingTimeReportLoaded(tReportData, showComparison: false),
      ],
    );

    blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Error')));
        return SpendingTimeReportBloc(
          getSpendingTimeReportUseCase: mockUseCase,
          reportFilterBloc: mockFilterBloc,
        );
      },
      expect: () => [
        isA<SpendingTimeReportLoading>(),
        const SpendingTimeReportError('Error'),
      ],
    );
  });

  group('ChangeGranularity', () {
    blocTest<SpendingTimeReportBloc, SpendingTimeReportState>(
      'emits [loading, loaded] with new granularity',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tReportData));
        return SpendingTimeReportBloc(
          getSpendingTimeReportUseCase: mockUseCase,
          reportFilterBloc: mockFilterBloc,
        );
      },
      act: (bloc) =>
          bloc.add(const ChangeGranularity(TimeSeriesGranularity.weekly)),
      expect: () => [
        isA<SpendingTimeReportLoading>(), // Initial
        isA<SpendingTimeReportLoaded>(),
        isA<SpendingTimeReportLoading>().having((s) => s.granularity,
            'granularity', TimeSeriesGranularity.weekly), // Reload
        isA<SpendingTimeReportLoaded>(),
      ],
    );
  });
}
