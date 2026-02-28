import 'dart:async';
import 'dart:io';
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
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class MockAddExpenseRepository extends Mock implements AddExpenseRepository {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockSplitPreviewEngine extends Mock implements SplitPreviewEngine {}

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseStorage extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockBox<T> extends Mock implements Box<T> {}

class MockUuid extends Mock implements Uuid {}

class MockXFile extends Mock implements XFile {}

class FakeAddExpenseWizardState extends Fake implements AddExpenseWizardState {}

void main() {
  late AddExpenseWizardBloc bloc;
  late MockAddExpenseRepository repository;
  late MockGroupsRepository groupsRepository;
  late MockSplitPreviewEngine splitEngine;
  late MockImageCompressionService imageCompressionService;
  late MockSupabaseClient supabase;
  late MockSupabaseStorage supabaseStorage;
  late MockStorageFileApi storageFileApi;
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

  const testCategory = Category(
    id: 'cat-1',
    name: 'Food',
    iconName: 'fastfood',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeAddExpenseWizardState());
    registerFallbackValue(const FileOptions());
    registerFallbackValue(File(''));
  });

  setUp(() {
    repository = MockAddExpenseRepository();
    groupsRepository = MockGroupsRepository();
    splitEngine = MockSplitPreviewEngine();
    imageCompressionService = MockImageCompressionService();
    supabase = MockSupabaseClient();
    supabaseStorage = MockSupabaseStorage();
    storageFileApi = MockStorageFileApi();
    profileBox = MockBox<ProfileModel>();
    uuid = MockUuid();

    when(() => supabase.storage).thenReturn(supabaseStorage);
    when(() => supabaseStorage.from(any())).thenReturn(storageFileApi);

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

  group('AddExpenseWizardBloc Expansion', () {
    test('initial state is correct', () {
      expect(bloc.state.status, FormStatus.initial);
      expect(bloc.state.currentUserId, currentUserId);
      expect(bloc.state.amountTotal, 0.0);
    });

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'DescriptionChanged updates description',
      build: () => bloc,
      act: (bloc) => bloc.add(const DescriptionChanged('Lunch')),
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.description,
          'description',
          'Lunch',
        ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'CategorySelected updates category',
      build: () => bloc,
      act: (bloc) => bloc.add(const CategorySelected(testCategory)),
      expect: () => [
        isA<AddExpenseWizardState>()
            .having((s) => s.categoryId, 'categoryId', 'cat-1')
            .having(
              (s) => s.selectedCategory,
              'selectedCategory',
              testCategory,
            ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'DateChanged updates expenseDate',
      build: () => bloc,
      act: (bloc) {
        final date = DateTime(2023, 10, 10);
        bloc.add(DateChanged(date));
      },
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.expenseDate,
          'expenseDate',
          DateTime(2023, 10, 10),
        ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'ReceiptSelected updates receiptLocalPath and uploads to cloud',
      build: () {
        final mockXFile = MockXFile();
        when(() => mockXFile.path).thenReturn('/compressed/path.jpg');
        when(
          () => imageCompressionService.compressImage(any()),
        ).thenAnswer((_) async => mockXFile);
        when(
          () => storageFileApi.upload(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => storageFileApi.getPublicUrl(any()),
        ).thenReturn('https://cloud.url/image.jpg');
        return bloc;
      },
      act: (bloc) => bloc.add(const ReceiptSelected('/path/to/image.jpg')),
      expect: () => [
        isA<AddExpenseWizardState>()
            .having(
              (s) => s.receiptLocalPath,
              'localPath',
              '/path/to/image.jpg',
            )
            .having((s) => s.isUploadingReceipt, 'isUploading', true),
        isA<AddExpenseWizardState>()
            .having((s) => s.isUploadingReceipt, 'isUploading', false)
            .having(
              (s) => s.receiptCloudUrl,
              'cloudUrl',
              'https://cloud.url/image.jpg',
            ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'SplitModeChanged updates splitMode and recalculated splits',
      build: () => bloc,
      act: (bloc) => bloc.add(const SplitModeChanged(SplitMode.percent)),
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.splitMode,
          'splitMode',
          SplitMode.percent,
        ),
        isA<AddExpenseWizardState>()
            .having((s) => s.splitMode, 'splitMode', SplitMode.percent)
            .having((s) => s.isSplitValid, 'isValid', false),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'SinglePayerSelected updates payers',
      build: () {
        when(
          () => groupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(testMembers));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(GroupSelected(testGroup));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SinglePayerSelected('user-2'));
      },
      skip: 3,
      expect: () => [
        isA<AddExpenseWizardState>()
            .having((s) => s.payers.length, 'payers length', 1)
            .having((s) => s.payers[0].userId, 'payer userId', 'user-2'),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'SubmitExpense fails with repository error',
      build: () {
        when(
          () => repository.createExpense(any()),
        ).thenThrow(Exception('Failed to create'));
        return bloc;
      },
      act: (bloc) => bloc
        ..add(const AmountChanged(50.0))
        ..add(const SubmitExpense()),
      skip: 1,
      expect: () => [
        isA<AddExpenseWizardState>().having(
          (s) => s.status,
          'status',
          FormStatus.processing,
        ),
        isA<AddExpenseWizardState>()
            .having((s) => s.status, 'status', FormStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Exception: Failed to create'),
            ),
      ],
    );

    blocTest<AddExpenseWizardBloc, AddExpenseWizardState>(
      'WizardStarted resets status and transactionId',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const WizardStarted());
      },
      expect: () => [
        isA<AddExpenseWizardState>()
            .having((s) => s.status, 'status reset', FormStatus.initial)
            .having((s) => s.transactionId, 'new tx id', 'test-uuid'),
      ],
    );
  });
}
