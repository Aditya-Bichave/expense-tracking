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

  testWidgets('showFilterSheet triggers timeout handling correctly', (tester) async {
    // We want the bloc state to NOT be loaded so it tries to load options and wait.
    when(() => mockBloc.state).thenReturn(ReportFilterState.initial().copyWith(optionsStatus: FilterOptionsStatus.initial));
    // Stream never emits, causing timeout
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      BlocProvider<ReportFilterBloc>.value(
        value: mockBloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ReportFilterControls.showFilterSheet(ctx),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap to show filter sheet
    await tester.tap(find.text('Show'));
    await tester.pump();

    // Fast-forward past the 3-second timeout duration for firstWhere
    await tester.pump(const Duration(seconds: 4));

    // Check that LoadFilterOptions was called
    verify(() => mockBloc.add(const LoadFilterOptions(forceReload: true))).called(1);

    // Ensure we don't have errors and the dialog doesn't show up if it's still loading
    expect(find.byType(ReportFilterSheetContent), findsNothing);
  });
}
