import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockNavigateToDetail extends Mock {
  void call(BuildContext context, TransactionEntity transaction);
}

void main() {
  late TransactionListBloc mockTransactionListBloc;
  late MockNavigateToDetail mockNavigateToDetail;

  final mockTransactions = [
    TransactionEntity(
        id: '1',
        title: 'Txn 1',
        amount: 10,
        date: DateTime.now(),
        type: TransactionType.expense),
    TransactionEntity(
        id: '2',
        title: 'Txn 2',
        amount: 20,
        date: DateTime.now(),
        type: TransactionType.expense),
  ];

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockNavigateToDetail = MockNavigateToDetail();
  });

  Widget buildTestWidget(TransactionListState state) {
    when(() => mockTransactionListBloc.state).thenReturn(state);
    return BlocProvider.value(
      value: mockTransactionListBloc,
      child: RecentTransactionsSection(
          navigateToDetailOrEdit: mockNavigateToDetail.call),
    );
  }

  group('RecentTransactionsSection', () {
    testWidgets('shows loading indicator', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          settle: false, // Don't settle infinite animation
          widget: buildTestWidget(
              const TransactionListState(status: ListStatus.loading)));

      // We need to pump a frame to allow the widget to build
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));

      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('Start tracking your spending'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders a list of TransactionListItems', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions)));
      expect(find.byType(TransactionListItem), findsNWidgets(2));
    });

    testWidgets('"View All" button is present', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));

      expect(find.byKey(const ValueKey('button_recentTransactions_viewAll')), findsOneWidget);
    });

    testWidgets('tapping a list item calls navigateToDetailOrEdit',
        (tester) async {
      when(() => mockNavigateToDetail.call(any(), any())).thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions)));

      await tester.tap(find.byType(TransactionListItem).first);

      verify(() => mockNavigateToDetail.call(any(), mockTransactions.first))
          .called(1);
    });
  });
}
