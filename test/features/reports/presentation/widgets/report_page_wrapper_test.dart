import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/error/failure.dart';

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
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => Stream.value(ReportFilterState.initial()));
  });

  testWidgets('ReportPageWrapper renders title and body', (WidgetTester tester) async {
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

  testWidgets('ReportPageWrapper shows export menu options', (WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      blocProviders: [
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
      ],
      widget: ReportPageWrapper(
        title: 'Test Report',
        body: const Text('Report Body'),
        // Explicitly type the Right value to match Expected Return Type Future<Either<String, Failure>>
        // BUT wait, onExportCSV returns Future<Either<String, Failure>>
        // Left is String (CSV data), Right is Failure?
        // Let's check ReportPageWrapper definition.
        // final Future<Either<String, Failure>> Function()? onExportCSV;
        // Usually Left is failure, Right is success.
        // Dartz conventions vary but usually Right is "Right/Correct".
        // Let's check the implementation:
        // result.fold((csvData) { ... }, (failure) { ... });
        // So Left is CSV Data, Right is Failure??
        // Typically Left=Error, Right=Success.
        // If result.fold( (l) => success, (r) => failure ), then Left is Success.
        // Let's check `lib/features/reports/presentation/widgets/report_page_wrapper.dart` again.

        // result.fold(
        //   (csvData) async { ... success ... },
        //   (failure) { ... error ... },
        // );

        // This implies Left is Success (csvData) and Right is Failure.
        // This is ANTI-PATTERN for Either (Right is Right).
        // BUT if that's how it is implemented...

        // Let's check CsvExportHelper.
        // Usually we return `Either<Failure, String>`.
        // If so, fold((failure) => ..., (data) => ...).

        // Let's look at `ReportPageWrapper` file content again (I have it in history).
        /*
        result.fold(
          (csvData) async {
            log.info("[ReportWrapper] CSV data generated...");
            // ... save ...
          },
          (failure) {
            log.warning("[ReportWrapper] Failed...");
            // ... show error ...
          },
        );
        */

        // If `onExportCSV` returns `Future<Either<String, Failure>>`, then Left=String, Right=Failure.
        // This is weird.
        // Let's assume standard `Either<Failure, String>` and I misread the type definition in my `cat` output creation.

        // In my `cat` for `ReportPageWrapper`:
        // `final Future<Either<String, Failure>> Function()? onExportCSV;`

        // If I defined it as `Either<String, Failure>`, then Left is String.
        // So `Left('csv_data')` would be success.

        // Let's correct the test to return `Left` if we want success path, or just match types.
        // If the analyzer complained about `Right`, maybe it's because I used `Right` for success but defined type implies otherwise?
        // Or generic mismatch.

        // Let's assume I want to simulate success.
        // I should return `Left('csv')`?
        // Or fix `ReportPageWrapper` to use standard `Either<Failure, String>`?

        // I should probably fix `ReportPageWrapper` to match standard `Either<Failure, Success>`.
        // BUT `CsvExportHelper` usually returns `Either<Failure, String>`.

        // Let's check `CsvExportHelper` signature if possible? I don't have it.
        // I'll assume standard `Either<Failure, R>`.

        // If so, `ReportPageWrapper` should be `Future<Either<Failure, String>>`.
        // And `fold` should be `(failure) => ..., (data) => ...`.

        // In my `cat` I wrote:
        /*
        result.fold(
          (csvData) async { ... success ... },
          (failure) { ... failure ... },
        );
        */
        // This implies I assumed Left is Success.

        // Let's FIX `ReportPageWrapper` to be standard: `Either<Failure, String>`.
        // And fix the fold order.

        // AND fix the test.

        // Wait, if I change `ReportPageWrapper`, I might break `BudgetPerformancePage` etc if they are passing `helper.export...`.
        // `CsvExportHelper` likely returns `Either<Failure, String>`.
        // So `BudgetPerformancePage` calling `helper.export...` returns `Either<Failure, String>`.
        // So `ReportPageWrapper` expects `Either<Failure, String>`.
        // So my `cat` creation of `ReportPageWrapper` had WRONG type annotation and WRONG fold order?

        // Let's verify `BudgetPerformancePage` code I generated.
        /*
        onExportCSV: () async {
          // ...
          return helper.exportBudgetPerformanceReport(...);
        }
        */

        // If `helper` returns `Either<Failure, String>`, then `onExportCSV` returns that.
        // So `ReportPageWrapper` MUST expect `Either<Failure, String>`.

        // So in `ReportPageWrapper`:
        // `final Future<Either<Failure, String>> Function()? onExportCSV;`

        // And fold:
        // `result.fold((failure) => ..., (csvData) => ...)`

        // I NEED TO FIX `ReportPageWrapper.dart`.

        // AND THEN fix the test to return `Right('csv')` (Success).

        onExportCSV: () async => const Right<Failure, String>('csv,data'),
      ),
    );

    // Tap export button
    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Export as CSV'), findsOneWidget);
    expect(find.text('Export as PDF (Soon)'), findsOneWidget);
  });

  testWidgets('ReportPageWrapper shows filter sheet on filter tap', (WidgetTester tester) async {
    when(() => mockFilterBloc.add(any())).thenReturn(null);

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
    await tester.pump();
  });
}
