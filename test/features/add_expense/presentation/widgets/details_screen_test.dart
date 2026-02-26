import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
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

  setUpAll(() {
    registerFallbackValue(const WizardStarted());
    registerFallbackValue(const DescriptionChanged(''));
  });

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

    sl.registerSingleton<GroupsRepository>(mockGroupsRepository);
    sl.registerSingleton<CategoryRepository>(mockCategoryRepository);
  });

  tearDown(() {
    sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AddExpenseWizardBloc>.value(
        value: mockBloc,
        child: DetailsScreen(onNext: (_) {}, onBack: () {}),
      ),
    );
  }

  testWidgets('DetailsScreen renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    // Correct text is "Personal" (from `state.selectedGroup?.name ?? 'Personal'`)
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Attach Receipt'), findsOneWidget);
    expect(find.text('Notes (Optional)'), findsOneWidget);
  });

  testWidgets('DetailsScreen entering description updates bloc', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find the AppTextField for Description
    final appTextFieldFinder = find.widgetWithText(AppTextField, 'Description');
    expect(appTextFieldFinder, findsOneWidget);

    // Find the TextFormField inside it
    final textFieldFinder = find.descendant(
      of: appTextFieldFinder,
      matching: find.byType(TextFormField),
    );
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, 'Test Expense');
    await tester.pump();

    verify(() => mockBloc.add(const DescriptionChanged('Test Expense')))
        .called(1);
  });
}
