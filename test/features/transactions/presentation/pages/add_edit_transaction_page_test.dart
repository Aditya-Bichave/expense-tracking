import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/liabilities/presentation/bloc/liability_list/liability_list_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
import 'package:expense_tracker/core/di/service_configurations/accounts_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/categories_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/liabilities_dependencies.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AddEditTransactionBloc mockBloc;
  late AccountListBloc mockAccountListBloc;
  late LiabilityListBloc mockLiabilityListBloc;

  setUpAll(() {
    Testhelpers.registerFallbacks();
    AccountDependencies.register();
    LiabilitiesDependencies.register();
    CategoriesDependencies.register();
  });

  setUp(() {
    mockBloc = MockAddEditTransactionBloc();
    mockAccountListBloc = MockAccountListBloc();
    mockLiabilityListBloc = MockLiabilityListBloc();
    if (!sl.isRegistered<AccountListBloc>()) {
      sl.registerLazySingleton<AccountListBloc>(() => mockAccountListBloc);
    }
    if (!sl.isRegistered<LiabilityListBloc>()) {
      sl.registerLazySingleton<LiabilityListBloc>(() => mockLiabilityListBloc);
    }
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
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockLiabilityListBloc.state)
          .thenReturn(const LiabilityListLoaded(liabilities: []));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        liabilityListBloc: mockLiabilityListBloc,
        widget: BlocProvider.value(
          value: mockBloc,
          child: const AddEditTransactionPage(initialTransactionData: null),
        ),
      );

      expect(
          find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Add Transaction')),
          findsOneWidget);
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
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockLiabilityListBloc.state)
          .thenReturn(const LiabilityListLoaded(liabilities: []));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        liabilityListBloc: mockLiabilityListBloc,
        widget: BlocProvider.value(
          value: mockBloc,
          child:
              AddEditTransactionPage(initialTransactionData: mockTransaction),
        ),
      );

      expect(
          find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Edit Transaction')),
          findsOneWidget);
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
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockLiabilityListBloc.state)
          .thenReturn(const LiabilityListLoaded(liabilities: []));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        liabilityListBloc: mockLiabilityListBloc,
        widget: BlocProvider.value(
          value: mockBloc,
          child: const AddEditTransactionPage(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success SnackBar when state is success', (tester) async {
      // ARRANGE
      final states = [
        const AddEditTransactionState(status: AddEditStatus.ready),
        const AddEditTransactionState(status: AddEditStatus.success)
      ];
      whenListen(mockBloc, Stream.fromIterable(states),
          initialState: states.first);
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockLiabilityListBloc.state)
          .thenReturn(const LiabilityListLoaded(liabilities: []));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        liabilityListBloc: mockLiabilityListBloc,
        widget: BlocProvider.value(
          value: mockBloc,
          child: const AddEditTransactionPage(),
        ),
      );
      await tester.pump(); // Pump once for the success state
      await tester.pump(); // Pump again for snackbar

      expect(find.text('Transaction added successfully!'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when state is error', (tester) async {
      // ARRANGE
      final states = [
        const AddEditTransactionState(status: AddEditStatus.ready),
        const AddEditTransactionState(
            status: AddEditStatus.error, errorMessage: 'Oh no!')
      ];
      whenListen(mockBloc, Stream.fromIterable(states),
          initialState: states.first);
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockLiabilityListBloc.state)
          .thenReturn(const LiabilityListLoaded(liabilities: []));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        liabilityListBloc: mockLiabilityListBloc,
        widget: BlocProvider.value(
          value: mockBloc,
          child: const AddEditTransactionPage(),
        ),
      );
      await tester.pump(); // Pump once for the error state
      await tester.pump(); // Pump again for snackbar

      expect(find.text('Error: Oh no!'), findsOneWidget);
    });
  });
}
