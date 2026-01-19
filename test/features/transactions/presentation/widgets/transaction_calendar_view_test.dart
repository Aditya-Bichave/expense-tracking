import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_calendar_view.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../helpers/pump_app.dart';

class MockCallbacks extends Mock {
  List<TransactionEntity> getEventsForDay(DateTime day);
  void onDaySelected(DateTime selectedDay, DateTime focusedDay);
  void onFormatChanged(CalendarFormat format);
  void onPageChanged(DateTime focusedDay);
  void navigateToDetailOrEdit(
      BuildContext context, TransactionEntity transaction);
}

void main() {
  late MockCallbacks mockCallbacks;
  final testDay = DateTime.now();
  final mockTransactions = [
    TransactionEntity(
        id: '1',
        title: 'Transaction 1',
        amount: 10,
        date: testDay,
        type: TransactionType.expense),
  ];

  setUp(() {
    mockCallbacks = MockCallbacks();
    when(() => mockCallbacks.getEventsForDay(any())).thenReturn([]);
    when(() => mockCallbacks.getEventsForDay(testDay))
        .thenReturn(mockTransactions);
  });

  Widget buildTestWidget({
    List<TransactionEntity> selectedDayTransactions = const [],
  }) {
    return TransactionCalendarView(
      state: const TransactionListState(),
      settings: const SettingsState(),
      // accountNames: const {'1': 'Test Account'}, // Removed
      calendarFormat: CalendarFormat.month,
      focusedDay: testDay,
      selectedDay: testDay,
      selectedDayTransactions: selectedDayTransactions,
      currentTransactionsForCalendar: mockTransactions,
      getEventsForDay: mockCallbacks.getEventsForDay,
      onDaySelected: mockCallbacks.onDaySelected,
      onFormatChanged: mockCallbacks.onFormatChanged,
      onPageChanged: mockCallbacks.onPageChanged,
      navigateToDetailOrEdit: mockCallbacks.navigateToDetailOrEdit,
    );
  }

  group('TransactionCalendarView', () {
    testWidgets('renders TableCalendar and list of transactions',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(selectedDayTransactions: mockTransactions));

      expect(find.byWidgetPredicate((w) => w is TableCalendar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TransactionListItem), findsOneWidget);
    });

    testWidgets('shows empty message when no transactions on selected day',
        (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      expect(find.textContaining('No transactions on'), findsOneWidget);
    });

    testWidgets('calls onDaySelected when a day is tapped', (tester) async {
      when(() => mockCallbacks.onDaySelected(any(), any())).thenAnswer((_) {});
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.text('15')); // Tap a visible day

      verify(() => mockCallbacks.onDaySelected(any(), any())).called(1);
    });

    testWidgets('calls navigateToDetailOrEdit when a transaction is tapped',
        (tester) async {
      when(() => mockCallbacks.navigateToDetailOrEdit(any(), any()))
          .thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(selectedDayTransactions: mockTransactions));

      await tester.tap(find.byType(TransactionListItem));

      verify(() => mockCallbacks.navigateToDetailOrEdit(
          any(), mockTransactions.first)).called(1);
    });
  });
}
