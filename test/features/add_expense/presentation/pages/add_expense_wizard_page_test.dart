import 'package:expense_tracker/features/add_expense/presentation/pages/add_expense_wizard_page.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';

class MockAddExpenseWizardBloc
    extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState>
    implements AddExpenseWizardBloc {}

class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;
  late MockGroupsRepository mockGroupsRepository;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
    mockGroupsRepository = MockGroupsRepository();
    mockCategoryRepository = MockCategoryRepository();

    when(() => mockBloc.state).thenReturn(AddExpenseWizardState(
      expenseDate: DateTime.now(),
      transactionId: 'test-tx-id',
    ));
    when(() => mockGroupsRepository.getGroups())
        .thenAnswer((_) async => const Right(<GroupEntity>[]));
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => const Right(<Category>[]));

    sl.registerSingleton<AddExpenseWizardBloc>(mockBloc);
    sl.registerSingleton<GroupsRepository>(mockGroupsRepository);
    sl.registerSingleton<CategoryRepository>(mockCategoryRepository);
  });

  tearDown(() {
    sl.reset();
  });

  testWidgets('AddExpenseWizardPage navigates to DetailsScreen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddExpenseWizardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Enter Amount'), findsOneWidget);

    // Simulate entering amount and next
    // Since page controller is inside, we can't easily trigger it without tapping.
    // NumpadScreen onNext -> _nextPage

    // Enter '1'
    await tester.tap(find.text('1'));
    await tester.pump();

    // Tap Next FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
  });
}
