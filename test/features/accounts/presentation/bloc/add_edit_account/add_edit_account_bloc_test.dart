import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAddAssetAccountUseCase extends Mock
    implements AddAssetAccountUseCase {}

class MockUpdateAssetAccountUseCase extends Mock
    implements UpdateAssetAccountUseCase {}

class FakeAddAssetAccountParams extends Fake implements AddAssetAccountParams {}

class FakeUpdateAssetAccountParams extends Fake
    implements UpdateAssetAccountParams {}

void main() {
  late AddEditAccountBloc bloc;
  late MockAddAssetAccountUseCase mockAddUseCase;
  late MockUpdateAssetAccountUseCase mockUpdateUseCase;
  late StreamController<DataChangedEvent> mockStreamController;

  final tAccount = AssetAccount(
    id: '1',
    name: 'Test Account',
    type: AssetType.bank,
    initialBalance: 100,
    currentBalance: 100,
  );

  setUpAll(() {
    registerFallbackValue(FakeAddAssetAccountParams());
    registerFallbackValue(FakeUpdateAssetAccountParams());
  });

  setUp(() {
    mockAddUseCase = MockAddAssetAccountUseCase();
    mockUpdateUseCase = MockUpdateAssetAccountUseCase();
    mockStreamController = StreamController<DataChangedEvent>();

    // Setup GetIt
    GetIt.instance.reset();
    GetIt.instance.registerSingleton<StreamController<DataChangedEvent>>(
      mockStreamController,
      instanceName: 'dataChangeController',
    );

    bloc = AddEditAccountBloc(
      addAssetAccountUseCase: mockAddUseCase,
      updateAssetAccountUseCase: mockUpdateUseCase,
    );
  });

  tearDown(() {
    GetIt.instance.reset();
    mockStreamController.close();
  });

  group('AddEditAccountBloc', () {
    test('initial state is AddEditAccountState', () {
      expect(bloc.state, const AddEditAccountState());
    });

    blocTest<AddEditAccountBloc, AddEditAccountState>(
      'emits [submitting, success] when SaveAccountRequested succeeds (Add)',
      setUp: () {
        when(
          () => mockAddUseCase(any()),
        ).thenAnswer((_) async => Right(tAccount));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        SaveAccountRequested(
          name: 'Test Account',
          type: AssetType.bank,
          initialBalance: 100,
        ),
      ),
      expect: () => [
        const AddEditAccountState(status: FormStatus.submitting),
        const AddEditAccountState(status: FormStatus.success),
      ],
      verify: (_) {
        verify(() => mockAddUseCase(any())).called(1);
      },
    );

    blocTest<AddEditAccountBloc, AddEditAccountState>(
      'emits [submitting, error] when SaveAccountRequested fails (Add)',
      setUp: () {
        when(
          () => mockAddUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Error')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        SaveAccountRequested(
          name: 'Test Account',
          type: AssetType.bank,
          initialBalance: 100,
        ),
      ),
      expect: () => [
        const AddEditAccountState(status: FormStatus.submitting),
        AddEditAccountState(
          status: FormStatus.error,
          errorMessage: 'Database Error: Could not save account. Error',
        ),
      ],
    );
  });
}
