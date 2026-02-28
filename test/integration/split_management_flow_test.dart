import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/pages/add_expense_wizard_page.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/split_screen.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';

import 'package:go_router/go_router.dart';
import '../helpers/mocks.dart';
import '../helpers/mock_helpers.dart';
import '../helpers/pump_app.dart';

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

void main() {
  final sl = GetIt.instance;

  late MockAddExpenseRepository mockAddExpenseRepository;
  late MockGroupsRepository mockGroupsRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockImageCompressionService mockImageCompressionService;
  late MockSupabaseClient mockSupabase;
  late MockBox<ProfileModel> mockProfileBox;

  final testGroup = GroupEntity(
    id: 'group-1',
    name: 'Flatmates',
    type: GroupType.home,
    currency: 'INR',
    createdBy: 'user-1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testMembers = [
    GroupMember(
      id: 'm1',
      groupId: 'group-1',
      userId: 'user-1',
      role: GroupRole.admin,
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    GroupMember(
      id: 'm2',
      groupId: 'group-1',
      userId: 'user-2',
      role: GroupRole.member,
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

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

    sl.registerSingleton<AddExpenseRepository>(mockAddExpenseRepository);
    sl.registerSingleton<GroupsRepository>(mockGroupsRepository);
    sl.registerSingleton<CategoryRepository>(mockCategoryRepository);
    sl.registerSingleton<ImageCompressionService>(mockImageCompressionService);
    sl.registerSingleton<SupabaseClient>(mockSupabase);
    sl.registerSingleton<Box<ProfileModel>>(mockProfileBox);
    sl.registerSingleton<SplitPreviewEngine>(SplitPreviewEngine());

    sl.registerFactory<AddExpenseWizardBloc>(
      () => AddExpenseWizardBloc(
        repository: mockAddExpenseRepository,
        groupsRepository: mockGroupsRepository,
        currentUserId: 'user-1',
        splitEngine: sl<SplitPreviewEngine>(),
        imageCompressionService: mockImageCompressionService,
        supabase: mockSupabase,
        profileBox: mockProfileBox,
      ),
    );

    when(() => mockProfileBox.get(any())).thenReturn(null);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right(<Category>[]));
    when(
      () => mockGroupsRepository.getGroups(),
    ).thenAnswer((_) async => Right([testGroup]));
    when(
      () => mockGroupsRepository.getGroupMembers(any()),
    ).thenAnswer((_) async => Right(testMembers));
  });

  testWidgets(
    'Integration: Split Management Flow (Group Select -> Split Mode -> Change Share -> Submit)',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/add-expense',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/add-expense',
            builder: (context, state) => const AddExpenseWizardPage(),
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SizedBox(),
        router: router,
      );

      // 1. Numpad: Enter 100
      await tester.tap(find.text('1'));
      await tester.tap(
        find.descendant(of: find.byType(Column), matching: find.text('0')).last,
      );
      await tester.tap(
        find.descendant(of: find.byType(Column), matching: find.text('0')).last,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // 2. Details: Select Group
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flatmates'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // 3. Split Screen
      expect(find.byType(SplitScreen), findsOneWidget);
      expect(find.textContaining('100.00'), findsOneWidget);

      // Default Equal split
      expect(find.text('user-1'), findsOneWidget);
      expect(find.text('user-2'), findsOneWidget);
      expect(find.textContaining('50.00'), findsNWidgets(2));

      // Change Mode to Percentages
      await tester.tap(find.text('Percentages'));
      await tester.pumpAndSettle();

      // Find TextField for user-1
      final user1Row = find
          .ancestor(of: find.text('user-1'), matching: find.byType(Row))
          .first;
      final user1PercentField = find.descendant(
        of: user1Row,
        matching: find.byType(TextField),
      );

      await tester.enterText(user1PercentField, '70');
      await tester.pumpAndSettle();

      // user-2 still at 50% (initial equal split was 50/50)
      // Total is 120%, should show validation error
      expect(find.text('Total percentage must be 100%'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      // Button should be disabled (onPressed is null)
      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'SAVE'),
      );
      expect(saveButton.onPressed, isNull);

      // Change user-2 to 30%
      final user2Row = find
          .ancestor(of: find.text('user-2'), matching: find.byType(Row))
          .first;
      final user2PercentField = find.descendant(
        of: user2Row,
        matching: find.byType(TextField),
      );
      await tester.enterText(user2PercentField, '30');
      await tester.pumpAndSettle();

      expect(find.text('Total percentage must be 100%'), findsNothing);
      expect(find.textContaining('70.00'), findsOneWidget);
      expect(find.textContaining('30.00'), findsOneWidget);

      // Mock successful submission
      when(
        () => mockAddExpenseRepository.createExpense(any()),
      ).thenAnswer((_) async => const Right(null));

      // Tap 'SAVE'
      final activeSaveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'SAVE'),
      );
      expect(activeSaveButton.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(TextButton, 'SAVE'));
      await tester.pumpAndSettle();

      // Verify submission
      verify(() => mockAddExpenseRepository.createExpense(any())).called(1);
    },
  );
}
