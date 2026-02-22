import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAddEditTransactionBloc
    extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockAddEditTransactionBloc mockBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCategoryManagementBloc mockCategoryManagementBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUpAll(() {
    registerFallbackValue(
      const AddEditTransactionState(transactionType: TransactionType.expense),
    );
    registerFallbackValue(const InitializeTransaction());
    registerFallbackValue(const AccountListLoaded(accounts: []));
  });

  setUp(() {
    mockBloc = MockAddEditTransactionBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    mockAccountListBloc = MockAccountListBloc();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<AddEditTransactionBloc>(mockBloc);
    getIt.registerSingleton<SettingsBloc>(mockSettingsBloc);
    getIt.registerSingleton<CategoryManagementBloc>(mockCategoryManagementBloc);
    getIt.registerSingleton<AccountListBloc>(mockAccountListBloc);

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockCategoryManagementBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        ),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddEditTransactionPage(),
      ),
    );
  }

  testWidgets('renders AddEditTransactionPage', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const AddEditTransactionState(transactionType: TransactionType.expense),
    );
    when(() => mockBloc.add(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(AddEditTransactionPage), findsOneWidget);
  });
}
