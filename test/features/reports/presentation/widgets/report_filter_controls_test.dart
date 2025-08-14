import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

class FakeReportFilterState extends Fake implements ReportFilterState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeReportFilterEvent());
    registerFallbackValue(FakeReportFilterState());
  });

  testWidgets('disables apply button and shows loading indicator', (
    tester,
  ) async {
    final bloc = MockReportFilterBloc();
    when(() => bloc.state).thenReturn(
      ReportFilterState.initial().copyWith(
        optionsStatus: FilterOptionsStatus.loading,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ReportFilterBloc>.value(
            value: bloc,
            child: const ReportFilterSheetContent(),
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final ElevatedButton button = tester.widget(
      find.widgetWithText(ElevatedButton, 'Loading options...'),
    );
    expect(button.onPressed, isNull);
  });
}
