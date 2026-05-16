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
}
