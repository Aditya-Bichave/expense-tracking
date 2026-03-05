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

  testWidgets(
    'showFilterSheet does not show bottom sheet if context unmounted after wait',
    (tester) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          ReportFilterState.initial().copyWith(
            optionsStatus: FilterOptionsStatus.loaded,
          ),
        ]),
      );

      await tester.pumpWidget(createWidget());

      final element = tester.element(find.byType(ReportFilterControls));

      // Start the async operation but don't await it yet
      final future = ReportFilterControls.showFilterSheet(element);

      // Pump a different widget to unmount the original one
      await tester.pumpWidget(const SizedBox());

      // Now await the future
      await future;

      // Bottom sheet should not appear
      expect(find.byType(BottomSheet), findsNothing);
    },
  );
}
