import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/income_vs_expense_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class MockIncomeExpenseReportBloc
    extends MockBloc<IncomeExpenseReportEvent, IncomeExpenseReportState>
    implements IncomeExpenseReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeIncomeExpenseReportEvent extends Fake
    implements IncomeExpenseReportEvent {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeIncomeExpenseReportEvent());
    registerFallbackValue(FakeReportFilterEvent());
    registerFallbackValue(FakeSettingsEvent());
  });

  testWidgets(
    'tapping income cell plays click sound and chart uses AspectRatio',
    (tester) async {
      final reportBloc = MockIncomeExpenseReportBloc();
      final filterBloc = MockReportFilterBloc();
      final settingsBloc = MockSettingsBloc();

      final periodData = IncomeExpensePeriodData(
        periodStart: DateTime(2024, 1, 1),
        totalIncome: const ComparisonValue(
          currentValue: 100,
          previousValue: 80,
        ),
        totalExpense: const ComparisonValue(
          currentValue: 50,
          previousValue: 40,
        ),
      );
      final loadedState = IncomeExpenseReportLoaded(
        IncomeExpenseReportData(
          periodData: [periodData],
          periodType: IncomeExpensePeriodType.monthly,
        ),
        showComparison: false,
      );
      when(() => reportBloc.state).thenReturn(loadedState);
      whenListen(reportBloc, Stream.value(loadedState));

      final filterState = ReportFilterState.initial();
      when(() => filterBloc.state).thenReturn(filterState);
      whenListen(filterBloc, Stream.value(filterState));

      const settingsState = SettingsState();
      when(() => settingsBloc.state).thenReturn(settingsState);
      whenListen(settingsBloc, Stream.value(settingsState));

      bool clicked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'SystemSound.play') {
              clicked = true;
            }
            return null;
          });

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const IncomeVsExpensePage()),
          GoRoute(
            path: RouteNames.transactionsList,
            builder: (_, __) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<IncomeExpenseReportBloc>.value(value: reportBloc),
            BlocProvider<ReportFilterBloc>.value(value: filterBloc),
            BlocProvider<SettingsBloc>.value(value: settingsBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AspectRatio), findsOneWidget);

      final table = tester.widget<DataTable>(find.byType(DataTable));
      runZonedGuarded(() {
        table.rows.first.cells[1].onTap!();
      }, (_, __) {});

      expect(clicked, isTrue);
    },
  );
}
