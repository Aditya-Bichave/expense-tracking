import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

class MockAddEditTransactionBloc
    extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

void main() {
  late AddEditTransactionBloc mockBloc;

  setUp(() {
    mockBloc = MockAddEditTransactionBloc();
    // Register the mock bloc instance for the service locator
    sl.registerFactory<AddEditTransactionBloc>(() => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  final mockTransaction = TransactionEntity(
    id: '1',
    title: 'Test',
    amount: 100,
    date: DateTime.now(),
    type: TransactionType.expense,
  );

  group('AddEditTransactionPage', () {
    testWidgets('renders correct AppBar title for "Add" mode', (tester) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AddEditTransactionState(status: AddEditStatus.ready)]),
        initialState:
            const AddEditTransactionState(status: AddEditStatus.ready),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditTransactionPage(initialTransactionData: null),
      );

      // ASSERT
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.byType(TransactionForm), findsOneWidget);
    });

    testWidgets('renders correct AppBar title for "Edit" mode', (tester) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.fromIterable([
          AddEditTransactionState(
              status: AddEditStatus.ready, transactionId: mockTransaction.id)
        ]),
        initialState: AddEditTransactionState(
            status: AddEditStatus.ready, transactionId: mockTransaction.id),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AddEditTransactionPage(initialTransactionData: mockTransaction),
      );

      // ASSERT
      expect(find.text('Edit Transaction'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is saving', (tester) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AddEditTransactionState(status: AddEditStatus.saving)]),
        initialState:
            const AddEditTransactionState(status: AddEditStatus.saving),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditTransactionPage(),
      );

      // ASSERT
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success SnackBar when state is success', (tester) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AddEditTransactionState(status: AddEditStatus.success)]),
        initialState:
            const AddEditTransactionState(status: AddEditStatus.ready),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditTransactionPage(),
      );
      await tester.pump(); // Pump to show snackbar

      // ASSERT
      expect(find.text('Transaction added successfully!'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when state is error', (tester) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const AddEditTransactionState(
              status: AddEditStatus.error, errorMessage: 'Oh no!')
        ]),
        initialState:
            const AddEditTransactionState(status: AddEditStatus.ready),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditTransactionPage(),
      );
      await tester.pump();

      // ASSERT
      expect(find.text('Error: Oh no!'), findsOneWidget);
    });
  });
}
