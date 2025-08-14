import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_by_category_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSpendingCategoryReportBloc
    extends MockBloc<SpendingCategoryReportEvent, SpendingCategoryReportState>
    implements SpendingCategoryReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeSpendingCategoryReportEvent extends Fake
    implements SpendingCategoryReportEvent {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeSpendingCategoryReportEvent());
    registerFallbackValue(FakeReportFilterEvent());
    registerFallbackValue(FakeSettingsEvent());
  });

  testWidgets('tapping data row plays click sound', (tester) async {
    final reportBloc = MockSpendingCategoryReportBloc();
    final filterBloc = MockReportFilterBloc();
    final settingsBloc = MockSettingsBloc();

    final reportData = SpendingCategoryReportData(
      totalSpending: const ComparisonValue(
        currentValue: 100,
        previousValue: 80,
      ),
      spendingByCategory: const [
        CategorySpendingData(
          categoryId: '1',
          categoryName: 'Food',
          categoryColor: Colors.red,
          totalAmount: ComparisonValue(currentValue: 100, previousValue: 80),
          percentage: 1.0,
        ),
      ],
    );
    final loadedState = SpendingCategoryReportLoaded(
      reportData,
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

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SpendingByCategoryPage()),
      GoRoute(
          path: RouteNames.transactionsList,
          builder: (_, __) => const SizedBox()),
    ]);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<SpendingCategoryReportBloc>.value(value: reportBloc),
        BlocProvider<ReportFilterBloc>.value(value: filterBloc),
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    final table = tester.widget<DataTable>(find.byType(DataTable));
    runZonedGuarded(() {
      table.rows.first.onSelectChanged!(true);
    }, (_, __) {});

    expect(clicked, isTrue);
  });
}
