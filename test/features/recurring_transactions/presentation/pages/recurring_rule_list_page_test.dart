import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/recurring_rule_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';

class MockRecurringListBloc
    extends MockBloc<RecurringListEvent, RecurringListState>
    implements RecurringListBloc {}

void main() {
  late MockRecurringListBloc mockBloc;

  setUp(() {
    mockBloc = MockRecurringListBloc();
    GetIt.I.registerSingleton<RecurringListBloc>(mockBloc);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('RecurringRuleListPage renders empty state', (
    WidgetTester tester,
  ) async {
    when(() => mockBloc.state).thenReturn(const RecurringListLoaded([]));

    await tester.pumpWidget(const MaterialApp(home: RecurringRuleListPage()));

    expect(find.text('No recurring rules found.'), findsOneWidget);
  });

  testWidgets('RecurringRuleListPage renders loading state', (
    WidgetTester tester,
  ) async {
    // Remove const
    when(() => mockBloc.state).thenReturn(RecurringListLoading());

    await tester.pumpWidget(const MaterialApp(home: RecurringRuleListPage()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
