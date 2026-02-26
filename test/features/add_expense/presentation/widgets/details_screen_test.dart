// ignore_for_file: directives_ordering

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAddExpenseWizardBloc extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState> implements AddExpenseWizardBloc {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockGroupsRepository extends Mock implements GroupsRepository {}
class FakeAddExpenseWizardState extends Fake implements AddExpenseWizardState {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;
  late MockCategoryRepository mockCategoryRepository;
  late MockGroupsRepository mockGroupsRepository;
  final tDate = DateTime(2023, 1, 1);

  setUpAll(() {
    registerFallbackValue(FakeAddExpenseWizardState());
    registerFallbackValue(const DescriptionChanged(''));
  });

  setUp(() async {
    mockBloc = MockAddExpenseWizardBloc();
    mockCategoryRepository = MockCategoryRepository();
    mockGroupsRepository = MockGroupsRepository();

    // Reset GetIt
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<CategoryRepository>(mockCategoryRepository);
    GetIt.instance.registerSingleton<GroupsRepository>(mockGroupsRepository);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AddExpenseWizardBloc>.value(
        value: mockBloc,
        child: DetailsScreen(
          onNext: (isGroup) {},
          onBack: () {},
        ),
      ),
    );
  }

  group('DetailsScreen', () {
    testWidgets('renders input fields and loads categories', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));
       when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => const Right(<Category>[]));

       await tester.pumpWidget(createWidgetUnderTest());
       await tester.pumpAndSettle(); // Wait for FutureBuilder

       expect(find.text('Details'), findsOneWidget);
       expect(find.byType(TextField), findsNWidgets(2)); // Description + Notes
       expect(find.text('Description'), findsOneWidget);
       expect(find.text('Notes (Optional)'), findsOneWidget);
    });

    testWidgets('populates description from state', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(
         currentUserId: 'u1',
         transactionId: 't1',
         expenseDate: tDate,
         description: 'Lunch'
       ));
       when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => const Right(<Category>[]));

       await tester.pumpWidget(createWidgetUnderTest());
       await tester.pumpAndSettle();

       expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('updates description on change', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));
       when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => const Right(<Category>[]));

       await tester.pumpWidget(createWidgetUnderTest());
       await tester.pumpAndSettle();

       await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Dinner');

       verify(() => mockBloc.add(const DescriptionChanged('Dinner'))).called(1);
    });

    testWidgets('displays categories and allows selection', (tester) async {
       final tCategory = Category(id: 'c1', name: 'Food', iconName: 'food', colorHex: 'FFF', isCustom: false, type: CategoryType.expense);

       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));
       // Use explicit type for Right to avoid dynamic inference issues
       when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => Right<Failure, List<Category>>([tCategory]));

       // Verify SL setup
       final repo = GetIt.instance<CategoryRepository>();
       expect(repo, mockCategoryRepository);

       await tester.pumpWidget(createWidgetUnderTest());
       await tester.pump(); // Start Future
       await tester.pump(const Duration(milliseconds: 100)); // Wait for future completion
       await tester.pumpAndSettle(); // Settle animations

       // Verify repository was called
       verify(() => mockCategoryRepository.getAllCategories()).called(greaterThan(0));

       // Check if error state is shown
       if (find.text('Error loading categories').evaluate().isNotEmpty) {
         fail('Categories failed to load');
       }

       // Check if still loading
       if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
         fail('Still loading categories');
       }

       // Verify ChoiceChip exists
       expect(find.byType(ChoiceChip), findsOneWidget);
       // Verify Label
       expect(find.text('Food'), findsOneWidget);

       await tester.tap(find.text('Food'));
       verify(() => mockBloc.add(any(that: isA<CategorySelected>()))).called(1);
    });
  });
}
