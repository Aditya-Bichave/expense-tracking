import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockSettingsBloc.stream,
    ).thenAnswer((_) => Stream<SettingsState>.empty().asBroadcastStream());
  });

  testWidgets('AssetDistributionSection renders chart', (tester) async {
    final accountBalances = {'Bank': 1000.0};

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: mockSettingsBloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AssetDistributionSection(accountBalances: accountBalances),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssetDistributionSection), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AssetDistributionSection),
        matching: find.byType(AssetDistributionPieChart),
      ),
      findsOneWidget,
    );
  });
}
