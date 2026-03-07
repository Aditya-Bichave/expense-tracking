import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockReportFilterBloc extends Mock implements ReportFilterBloc {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

void main() {
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(FakeReportFilterEvent());
  });

  setUp(() {
    mockFilterBloc = MockReportFilterBloc();
    final loadedState = ReportFilterState.initial().copyWith(
      optionsStatus: FilterOptionsStatus.loaded,
    );

    when(() => mockFilterBloc.state).thenReturn(loadedState);
    when(
      () => mockFilterBloc.stream,
    ).thenAnswer((_) => Stream.value(loadedState));
    when(() => mockFilterBloc.add(any())).thenReturn(null);
  });

  testWidgets('ReportPageWrapper renders title and body', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
      ],
      widget: const ReportPageWrapper(
        title: 'Test Report',
        body: Text('Report Body'),
      ),
    );

    expect(find.text('Test Report'), findsOneWidget);
    expect(find.text('Report Body'), findsOneWidget);
  });

  testWidgets('ReportPageWrapper shows export menu options', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
      ],
      widget: ReportPageWrapper(
        title: 'Test Report',
        body: const Text('Report Body'),
        onExportCSV: () async => const Right<Failure, String>('csv,data'),
      ),
    );

    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Export as CSV'), findsOneWidget);
    expect(find.text('Export as PDF (Soon)'), findsOneWidget);
  });

  testWidgets('ReportPageWrapper shows filter sheet on filter tap', (
    tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
      ],
      widget: const ReportPageWrapper(
        title: 'Test Report',
        body: Text('Report Body'),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
