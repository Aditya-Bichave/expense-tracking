import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_chip.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';

class MockAddExpenseWizardBloc
    extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState>
    implements AddExpenseWizardBloc {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;
  late MockGroupsRepository mockGroupsRepository;
  late MockCategoryRepository mockCategoryRepository;

  final testCategory = Category(
    id: 'food',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: false,
  );

  setUpAll(() {
    registerFallbackValue(const WizardStarted());
    registerFallbackValue(const DescriptionChanged(''));
    registerFallbackValue(CategorySelected(testCategory));
    registerFallbackValue(DateChanged(DateTime.now()));
  });

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
    mockGroupsRepository = MockGroupsRepository();
    mockCategoryRepository = MockCategoryRepository();

    when(() => mockBloc.state).thenReturn(
      AddExpenseWizardState(
        expenseDate: DateTime.now(),
        transactionId: 'test-tx-id',
      ),
    );
    when(
      () => mockGroupsRepository.getGroups(),
    ).thenAnswer((_) async => const Right(<GroupEntity>[]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([testCategory]));

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
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Attach Receipt'), findsOneWidget);
    expect(find.text('Notes (Optional)'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget); // Category chip
  });

  testWidgets('DetailsScreen entering description updates bloc', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final appTextFieldFinder = find.widgetWithText(AppTextField, 'Description');
    final textFieldFinder = find.descendant(
      of: appTextFieldFinder,
      matching: find.byType(TextFormField),
    );

    await tester.enterText(textFieldFinder, 'Test Expense');
    await tester.pump();

    verify(
      () => mockBloc.add(const DescriptionChanged('Test Expense')),
    ).called(1);
  });

  testWidgets('DetailsScreen selecting category updates bloc', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food'));
    await tester.pump();

    verify(() => mockBloc.add(CategorySelected(testCategory))).called(1);
    verify(() => mockBloc.add(const DescriptionChanged('Food'))).called(1);
  });

  testWidgets('DetailsScreen opens date picker', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find the AppCard containing the calendar icon
    final calendarIconFinder = find.byIcon(Icons.calendar_today);
    final appCardFinder = find.ancestor(
      of: calendarIconFinder,
      matching: find.byType(AppCard),
    );

    // Tap the AppCard
    await tester.tap(appCardFinder);
    await tester.pumpAndSettle();

    // Verify DatePicker is shown. The header typically contains year or "Select date"
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
