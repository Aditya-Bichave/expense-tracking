import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/pages/add_expense_wizard_page.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';

import '../helpers/mocks.dart';
import '../helpers/mock_helpers.dart';
import '../helpers/pump_app.dart';

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

class MockSplitPreviewEngine extends Mock implements SplitPreviewEngine {}

void main() {
  final sl = GetIt.instance;

  late MockAddExpenseRepository mockAddExpenseRepository;
  late MockGroupsRepository mockGroupsRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockImageCompressionService mockImageCompressionService;
  late MockSupabaseClient mockSupabase;
  late MockBox<ProfileModel> mockProfileBox;
  late MockSplitPreviewEngine mockSplitEngine;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() async {
    await sl.reset();

    mockAddExpenseRepository = MockAddExpenseRepository();
    mockGroupsRepository = MockGroupsRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockImageCompressionService = MockImageCompressionService();
    mockSupabase = MockSupabaseClient();
    mockProfileBox = MockBox<ProfileModel>();
    mockSplitEngine = MockSplitPreviewEngine();

    sl.registerSingleton<AddExpenseRepository>(mockAddExpenseRepository);
    sl.registerSingleton<GroupsRepository>(mockGroupsRepository);
    sl.registerSingleton<CategoryRepository>(mockCategoryRepository);
    sl.registerSingleton<ImageCompressionService>(mockImageCompressionService);
    sl.registerSingleton<SupabaseClient>(mockSupabase);
    sl.registerSingleton<Box<ProfileModel>>(mockProfileBox);
    sl.registerSingleton<SplitPreviewEngine>(mockSplitEngine);

    // Register the Bloc
    sl.registerFactory<AddExpenseWizardBloc>(
      () => AddExpenseWizardBloc(
        repository: mockAddExpenseRepository,
        groupsRepository: mockGroupsRepository,
        currentUserId: 'user-1',
        splitEngine: mockSplitEngine,
        imageCompressionService: mockImageCompressionService,
        supabase: mockSupabase,
        profileBox: mockProfileBox,
      ),
    );

    // Default stubs
    when(() => mockProfileBox.get(any())).thenReturn(null);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right(<Category>[]));
    when(
      () => mockGroupsRepository.getGroups(),
    ).thenAnswer((_) async => const Right([]));
  });

  testWidgets(
    'Integration: Expense Creation Flow (Numpad -> Details -> Submit)',
    (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddExpenseWizardPage(),
      );

      // 1. Numpad Screen: Enter 50.00
      expect(find.byType(NumpadScreen), findsOneWidget);

      // Tap '5' and '0'
      await tester.tap(find.text('5'));
      await tester.pump();
      // Target the '0' key specifically to avoid hitting the amount display
      await tester.tap(
        find
            .descendant(
              of: find.byType(Column), // The numpad column
              matching: find.text('0'),
            )
            .last, // The display is usually earlier in the tree
      );
      await tester.pump();

      expect(find.text('50'), findsOneWidget);

      // Tap 'Next'
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // 2. Details Screen
      expect(find.byType(DetailsScreen), findsOneWidget);

      // Enter Description
      await tester.enterText(find.byType(TextField).first, 'Dinner');
      await tester.pump();

      // Mock successful submission
      when(
        () => mockAddExpenseRepository.createExpense(any()),
      ).thenAnswer((_) async => const Right(null));

      // Tap 'SAVE'
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify submission called
      verify(() => mockAddExpenseRepository.createExpense(any())).called(1);

      // Should have popped back (or handled success)
      // AddExpenseWizardView listener calls Navigator.pop(context) on success state if it's there
    },
  );
}
