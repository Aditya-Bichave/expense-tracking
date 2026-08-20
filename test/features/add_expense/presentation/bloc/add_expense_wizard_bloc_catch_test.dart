import 'dart:io';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
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

class MockUuid extends Mock implements Uuid {}

class MockProfileBox extends Mock implements Box<ProfileModel> {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  late MockAddExpenseRepository mockRepository;
  late MockGroupsRepository mockGroupsRepository;
  late MockSplitPreviewEngine mockSplitEngine;
  late MockImageCompressionService mockImageCompressionService;
  late MockSupabaseClient mockSupabase;
  late MockUuid mockUuid;
  late MockProfileBox mockProfileBox;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockStorageFileApi;

  setUpAll(() {
    registerFallbackValue(File(''));
    registerFallbackValue(const FileOptions());
    registerFallbackValue(
      AddExpenseWizardState(transactionId: 'tx1', expenseDate: DateTime.now()),
    );
  });

  setUp(() {
    mockRepository = MockAddExpenseRepository();
    mockGroupsRepository = MockGroupsRepository();
    mockSplitEngine = MockSplitPreviewEngine();
    mockImageCompressionService = MockImageCompressionService();
    mockSupabase = MockSupabaseClient();
    mockUuid = MockUuid();
    mockProfileBox = MockProfileBox();
    mockStorageClient = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();

    when(() => mockUuid.v4()).thenReturn('generated-uuid');
    when(() => mockSupabase.storage).thenReturn(mockStorageClient);
    when(() => mockStorageClient.from(any())).thenReturn(mockStorageFileApi);
    when(
      () => mockImageCompressionService.compressImage(any()),
    ).thenAnswer((inv) async => null);
  });

  test('AddExpenseWizardBloc handles catch in receipt upload error', () async {
    when(
      () => mockStorageFileApi.upload(
        any(),
        any(),
        fileOptions: any(named: 'fileOptions'),
      ),
    ).thenAnswer((_) async => throw Exception('upload error'));

    final bloc = AddExpenseWizardBloc(
      repository: mockRepository,
      groupsRepository: mockGroupsRepository,
      currentUserId: 'u1',
      splitEngine: mockSplitEngine,
      imageCompressionService: mockImageCompressionService,
      supabase: mockSupabase,
      uuid: mockUuid,
      profileBox: mockProfileBox,
    );

    bloc.add(const ReceiptSelected('/tmp/test.jpg'));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<AddExpenseWizardState>((s) => !s.isUploadingReceipt),
      ),
    );

    await bloc.close();
  });

  test('AddExpenseWizardBloc handles catch in SubmitExpense error', () async {
    when(
      () => mockRepository.createExpense(any()),
    ).thenAnswer((_) async => throw Exception('submit error'));

    final bloc = AddExpenseWizardBloc(
      repository: mockRepository,
      groupsRepository: mockGroupsRepository,
      currentUserId: 'u1',
      splitEngine: mockSplitEngine,
      imageCompressionService: mockImageCompressionService,
      supabase: mockSupabase,
      uuid: mockUuid,
      profileBox: mockProfileBox,
    );

    bloc.add(const SubmitExpense());

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<AddExpenseWizardState>((s) => s.status == FormStatus.error),
      ),
    );

    await bloc.close();
  });
}
