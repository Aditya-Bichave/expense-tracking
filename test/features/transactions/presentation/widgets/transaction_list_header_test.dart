@Skip('Needs stabilization')
library transaction_list_header_test;

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockVoidCallback extends Mock {
  void call();
}

class MockFunction extends Mock {
  void call(BuildContext context, TransactionListState state);
}

void main() {
  late TransactionListBloc mockBloc;
  late TextEditingController searchController;
  late MockVoidCallback onClearSearch;
  late MockVoidCallback onToggleCalendarView;
  late MockFunction showFilterDialog;
  late MockFunction showSortDialog;

  setUp(() {
    mockBloc = MockTransactionListBloc();
    searchController = TextEditingController();
    onClearSearch = MockVoidCallback();
    onToggleCalendarView = MockVoidCallback();
    showFilterDialog = MockFunction();
    showSortDialog = MockFunction();
  });

  tearDown(() {
    searchController.dispose();
  });

  Widget buildTestWidget(
      {TransactionListState? state, bool isCalendarView = false}) {
    when(() => mockBloc.state)
        .thenReturn(state ?? const TransactionListState());
    return BlocProvider.value(
      value: mockBloc,
      child: TransactionListHeader(
        searchController: searchController,
        onClearSearch: onClearSearch.call,
        onToggleCalendarView: onToggleCalendarView.call,
        isCalendarViewShown: isCalendarView,
        showFilterDialog: showFilterDialog.call,
        showSortDialog: showSortDialog.call,
      ),
    );
  }

  group('TransactionListHeader', () {
    testWidgets('renders all interactive elements', (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byKey(const ValueKey('textField_transactionSearch')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('button_show_filter')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_show_sort')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_toggle_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_toggle_batchEdit')),
          findsOneWidget);
    });

    testWidgets('calls callbacks when buttons are tapped', (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_show_filter')));
      verify(() => showFilterDialog.call(any(), any())).called(1);

      await tester.tap(find.byKey(const ValueKey('button_show_sort')));
      verify(() => showSortDialog.call(any(), any())).called(1);

      await tester.tap(find.byKey(const ValueKey('button_toggle_view')));
      verify(() => onToggleCalendarView.call()).called(1);
    });

    testWidgets(
        'dispatches ToggleBatchEdit event when batch edit button is tapped',
        (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      await tester.tap(find.byKey(const ValueKey('button_toggle_batchEdit')));
      verify(() => mockBloc.add(const ToggleBatchEdit())).called(1);
    });

    testWidgets('shows and calls clear button for search', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
              state: const TransactionListState(searchTerm: 'test')));

      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      verify(() => onClearSearch.call()).called(1);
    });

    testWidgets('shows correct icons for view and batch mode toggles',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
              isCalendarView: false,
              state: const TransactionListState(isInBatchEditMode: false)));
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.select_all_rounded), findsOneWidget);

      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
              isCalendarView: true,
              state: const TransactionListState(isInBatchEditMode: true)));
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
