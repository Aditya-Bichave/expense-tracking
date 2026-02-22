import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late MockCategoryManagementBloc mockCategoryBloc;

  setUp(() {
    mockCategoryBloc = MockCategoryManagementBloc();
    when(
      () => mockCategoryBloc.state,
    ).thenReturn(const CategoryManagementState());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CategoryManagementBloc>.value(value: mockCategoryBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionFilterDialog(
            onApplyFilter: _dummyApply,
            onClearFilter: _dummyClear,
            availableCategories: [],
          ),
        ),
      ),
    );
  }

  testWidgets('renders TransactionFilterDialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFilterDialog), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}

void _dummyApply(
  DateTime? start,
  DateTime? end,
  TransactionType? type,
  String? catId,
  String? accId,
) {}
void _dummyClear() {}
