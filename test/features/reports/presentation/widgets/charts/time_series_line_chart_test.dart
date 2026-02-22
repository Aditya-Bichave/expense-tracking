import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    // selectedCountryCode defaults to US which likely has '$' currency
    when(
      () => mockSettingsBloc.state,
    ).thenReturn(const SettingsState(selectedCountryCode: 'US'));
  });

  testWidgets('TimeSeriesLineChart renders empty state', (tester) async {
    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: MaterialApp(
          home: Scaffold(
            body: const TimeSeriesLineChart(
              data: [],
              granularity: TimeSeriesGranularity.daily,
            ),
          ),
        ),
      ),
    );

    expect(find.text('No data to display'), findsOneWidget);
  });
}
