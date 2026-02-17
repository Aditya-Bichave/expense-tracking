import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_over_time_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class MockSpendingTimeReportBloc
    extends MockBloc<SpendingTimeReportEvent, SpendingTimeReportState>
    implements SpendingTimeReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeSpendingTimeReportEvent extends Fake
    implements SpendingTimeReportEvent {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeSpendingTimeReportEvent());
    registerFallbackValue(FakeReportFilterEvent());
    registerFallbackValue(FakeSettingsEvent());
  });

  testWidgets('tapping data row plays click sound and chart uses AspectRatio', (
    tester,
  ) async {
    final spendingBloc = MockSpendingTimeReportBloc();
    final filterBloc = MockReportFilterBloc();
    final settingsBloc = MockSettingsBloc();

    final data = SpendingTimeReportData(
      spendingData: [
        TimeSeriesDataPoint(
          date: DateTime(2024, 1, 1),
          amount: const ComparisonValue(currentValue: 100, previousValue: 50),
        ),
      ],
      granularity: TimeSeriesGranularity.monthly,
    );
    final loadedState = SpendingTimeReportLoaded(data, showComparison: false);
    when(() => spendingBloc.state).thenReturn(loadedState);
    whenListen(spendingBloc, Stream.value(loadedState));

    final filterState = ReportFilterState.initial();
    when(() => filterBloc.state).thenReturn(filterState);
    whenListen(filterBloc, Stream.value(filterState));

    const settingsState = SettingsState(uiMode: UIMode.quantum);
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
        GoRoute(path: '/', builder: (_, __) => const SpendingOverTimePage()),
        GoRoute(
          path: RouteNames.transactionsList,
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );

    final theme = ThemeData(
      extensions: const [
        AppModeTheme(
          modeId: 'test',
          layoutDensity: LayoutDensity.compact,
          cardStyle: CardStyle.flat,
          assets: ThemeAssetPaths(),
          preferDataTableForLists: true,
          primaryAnimationDuration: Duration.zero,
          listEntranceAnimation: ListEntranceAnimation.none,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SpendingTimeReportBloc>.value(value: spendingBloc),
          BlocProvider<ReportFilterBloc>.value(value: filterBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AspectRatio), findsOneWidget);
    final dataTable = tester.widget<DataTable>(find.byType(DataTable));
    runZonedGuarded(() {
      dataTable.rows.first.onSelectChanged!(true);
    }, (_, __) {});

    expect(clicked, isTrue);
  });
}
