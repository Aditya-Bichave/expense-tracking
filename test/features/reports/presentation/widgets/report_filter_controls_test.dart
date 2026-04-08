import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_filter_controls.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late MockReportFilterBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(ReportFilterState.initial());
  });

  setUp(() {
    mockBloc = MockReportFilterBloc();
    when(() => mockBloc.state).thenReturn(ReportFilterState.initial());
  });

  Widget createWidget() {
    return BlocProvider<ReportFilterBloc>.value(
      value: mockBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReportFilterControls()),
      ),
    );
  }

  testWidgets('renders ReportFilterControls', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.byType(ReportFilterControls), findsOneWidget);
  });

  testWidgets('calls showFilterSheet and waits when stream is not loaded', (tester) async {
    whenListen(
      mockBloc,
      Stream.fromIterable([
        ReportFilterState.initial().copyWith(optionsStatus: FilterOptionsStatus.loading),
        ReportFilterState.initial().copyWith(optionsStatus: FilterOptionsStatus.loaded),
      ]),
      initialState: ReportFilterState.initial().copyWith(optionsStatus: FilterOptionsStatus.loading),
    );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Mock the UI to test only the stream subscription timeout inside the bottom sheet builder function
    // For this, we just need to ensure the report controls build.
    final widget = find.byType(ReportFilterControls);
    expect(widget, findsOneWidget);

    // Call the static method directly to test the timeout.
    ReportFilterControls.showFilterSheet(tester.element(widget));
    await tester.pumpAndSettle();

    verify(() => mockBloc.add(const LoadFilterOptions(forceReload: true))).called(1);
  });
}
