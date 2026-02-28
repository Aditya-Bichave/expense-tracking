import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MockAddExpenseRepository extends Mock implements AddExpenseRepository {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockSplitPreviewEngine extends Mock implements SplitPreviewEngine {}

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockBox<T> extends Mock implements Box<T> {}

class MockUuid extends Mock implements Uuid {}

class FakeAddExpenseWizardState extends Fake implements AddExpenseWizardState {}

void main() {
  late AddExpenseWizardBloc bloc;
  late MockAddExpenseRepository repository;
  late MockGroupsRepository groupsRepository;
  late MockSplitPreviewEngine splitEngine;
  late MockImageCompressionService imageCompressionService;
  late MockSupabaseClient supabase;
  late MockBox<ProfileModel> profileBox;
  late MockUuid uuid;

  const currentUserId = 'user-1';

  final testGroup = GroupEntity(
    id: 'group-1',
    name: 'Flatmates',
    type: GroupType.home,
    currency: 'USD',
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
    registerFallbackValue(FakeAddExpenseWizardState());
  });

  setUp(() {
    repository = MockAddExpenseRepository();
    groupsRepository = MockGroupsRepository();
    splitEngine = MockSplitPreviewEngine();
    imageCompressionService = MockImageCompressionService();
    supabase = MockSupabaseClient();
    profileBox = MockBox<ProfileModel>();
    uuid = MockUuid();

    when(() => uuid.v4()).thenReturn('test-uuid');
    when(() => profileBox.get(currentUserId)).thenReturn(
      ProfileModel(
        id: currentUserId,
        email: 'test@example.com',
        fullName: 'Test User',
        currency: 'USD',
        timezone: 'UTC',
      ),
    );

    bloc = AddExpenseWizardBloc(
      repository: repository,
      groupsRepository: groupsRepository,
      currentUserId: currentUserId,
      splitEngine: splitEngine,
      imageCompressionService: imageCompressionService,
      supabase: supabase,
      profileBox: profileBox,
      uuid: uuid,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AddExpenseWizardBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, FormStatus.initial);
      expect(bloc.state.currentUserId, currentUserId);
      expect(bloc.state.amountTotal, 0.0);
    });

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'AmountChanged updates amount',
      build: () => bloc,
      act: (bloc) => bloc.add(const AmountChanged(100.0)),
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.amountTotal,
          'amountTotal',
          100.0,
        ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'GroupSelected works correctly',
      build: () {
        when(
          () => groupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(testMembers));
        return bloc;
      },
      act: (bloc) => bloc.add(GroupSelected(testGroup)),
      expect: () => [
        isA<AddExpenseWizardState>()
            .having((s) => s.groupId, 'groupId', 'group-1')
            .having((s) => s.selectedGroup, 'selectedGroup', testGroup),
        isA<AddExpenseWizardState>()
            .having((s) => s.groupMembers.length, 'members length', 2)
            .having((s) => s.splits.length, 'splits length', 0),
        isA<AddExpenseWizardState>().having(
          (s) => s.splits.length,
          'splits length after default set',
          2,
        ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'AmountChanged recalculates splits when group is selected',
      build: () {
        when(
          () => groupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(testMembers));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(GroupSelected(testGroup));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const AmountChanged(100.0));
      },
      skip: 3,
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.amountTotal,
          'amountTotal',
          100.0,
        ),
        isA<AddExpenseWizardState>()
            .having((s) => s.amountTotal, 'amountTotal', 100.0)
            .having((s) => s.payers[0].amountPaid, 'payer 0 amount', 100.0),
        isA<AddExpenseWizardState>()
            .having((s) => s.amountTotal, 'amountTotal', 100.0)
            .having((s) => s.splits[0].computedAmount, 'split 0 amount', 50.0),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'SubmitExpense succeeds for personal expense',
      build: () {
        when(() => repository.createExpense(any())).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) => bloc
        ..add(const AmountChanged(50.0))
        ..add(const DescriptionChanged('Coffee'))
        ..add(const SubmitExpense()),
      skip: 2,
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.status,
          'status',
          FormStatus.processing,
        ),
        isA<AddExpenseWizardState>().having(
          (s) => s.status,
          'status',
          FormStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => repository.createExpense(any())).called(1);
      },
    );
  });
}
