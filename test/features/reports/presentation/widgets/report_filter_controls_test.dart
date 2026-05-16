import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_filter_controls.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportFilterBloc extends MockBloc<ReportFilterEvent, ReportFilterState> implements ReportFilterBloc {}

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
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ReportFilterControls(),
            floatingActionButton: FloatingActionButton(
              onPressed: () => ReportFilterControls.showFilterSheet(context),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders ReportFilterControls', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.byType(ReportFilterControls), findsOneWidget);
  });

  testWidgets('showFilterSheet handles stream timeout safely', (tester) async {
    // Setup stream that never emits 'loaded'
    final controller = StreamController<ReportFilterState>();
    when(() => mockBloc.stream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap to open sheet, which waits for stream
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    // Fast forward time to trigger timeout
    await tester.pump(const Duration(seconds: 4));

    // Should not crash, handled gracefully
    expect(find.byType(ReportFilterControls), findsOneWidget);
    controller.close();
  });
}
