import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetListBloc extends Mock implements BudgetListBloc {}

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late MockBudgetListBloc mockBudgetListBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
    when(
      () => mockBudgetListBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('BudgetsSubTab renders list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          ],
          child: const Scaffold(body: BudgetsSubTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BudgetsSubTab), findsOneWidget);
  });
}
