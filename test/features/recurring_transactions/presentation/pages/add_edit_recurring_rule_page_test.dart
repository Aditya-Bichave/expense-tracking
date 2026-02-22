import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/add_edit_recurring_rule_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Import AccountListBloc

class MockAddEditRecurringRuleBloc
    extends MockBloc<AddEditRecurringRuleEvent, AddEditRecurringRuleState>
    implements AddEditRecurringRuleBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockAccountListBloc
    extends
        MockBloc<AccountListEvent, AccountListState> // Mock AccountListBloc
    implements AccountListBloc {}

void main() {
  late MockAddEditRecurringRuleBloc mockBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCategoryManagementBloc mockCategoryManagementBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    mockBloc = MockAddEditRecurringRuleBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    mockAccountListBloc = MockAccountListBloc();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockCategoryManagementBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListInitial()); // Stub AccountListBloc
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AddEditRecurringRuleBloc>.value(value: mockBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<CategoryManagementBloc>.value(
          value: mockCategoryManagementBloc,
        ),
        BlocProvider<AccountListBloc>.value(
          value: mockAccountListBloc,
        ), // Provide AccountListBloc
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddEditRecurringRulePage(),
      ),
    );
  }

  testWidgets('renders AddEditRecurringRulePage', (tester) async {
    when(() => mockBloc.state).thenReturn(AddEditRecurringRuleState.initial());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(AddEditRecurringRulePage), findsOneWidget);
  });
}
