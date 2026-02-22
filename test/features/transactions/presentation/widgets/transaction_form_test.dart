import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAddEditTransactionBloc
    extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockCategoryManagementBloc mockCategoryBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockAddEditTransactionBloc mockAddEditBloc;
  late MockAccountListBloc mockAccountBloc;

  setUp(() {
    mockCategoryBloc = MockCategoryManagementBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockAddEditBloc = MockAddEditTransactionBloc();
    mockAccountBloc = MockAccountListBloc();
  });

  testWidgets('TransactionForm renders', (tester) async {
    when(
      () => mockCategoryBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockAddEditBloc.state,
    ).thenReturn(const AddEditTransactionState());
    when(
      () => mockAccountBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CategoryManagementBloc>.value(value: mockCategoryBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<AddEditTransactionBloc>.value(value: mockAddEditBloc),
            BlocProvider<AccountListBloc>.value(value: mockAccountBloc),
          ],
          child: Scaffold(
            body: TransactionForm(
              initialType: TransactionType.expense,
              onSubmit: (type, title, amount, date, cat, accId, notes) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
  });
}
