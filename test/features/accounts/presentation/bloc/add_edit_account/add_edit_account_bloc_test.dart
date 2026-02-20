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
import 'package:uuid/uuid.dart';

class MockAddAssetAccountUseCase extends Mock implements AddAssetAccountUseCase {}
class MockUpdateAssetAccountUseCase extends Mock implements UpdateAssetAccountUseCase {}
class MockUuid extends Mock implements Uuid {}

class FakeAddAssetAccountParams extends Fake implements AddAssetAccountParams {}
class FakeUpdateAssetAccountParams extends Fake implements UpdateAssetAccountParams {}

void main() {
  late AddEditAccountBloc bloc;
  late MockAddAssetAccountUseCase mockAddAssetAccountUseCase;
  late MockUpdateAssetAccountUseCase mockUpdateAssetAccountUseCase;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(FakeAddAssetAccountParams());
    registerFallbackValue(FakeUpdateAssetAccountParams());
  });

  setUp(() {
    mockAddAssetAccountUseCase = MockAddAssetAccountUseCase();
    mockUpdateAssetAccountUseCase = MockUpdateAssetAccountUseCase();
    mockUuid = MockUuid();

    GetIt.I.reset();
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    GetIt.I.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );

    bloc = AddEditAccountBloc(
      addAssetAccountUseCase: mockAddAssetAccountUseCase,
      updateAssetAccountUseCase: mockUpdateAssetAccountUseCase,
      uuid: mockUuid,
    );
  });

  tearDown(() {
    bloc.close();
    GetIt.I.reset();
  });

  final tAccount = AssetAccount(
    id: '1',
    name: 'Cash',
    type: AssetType.cash,
    initialBalance: 100.0,
    currentBalance: 100.0,
  );

  group('AddEditAccountBloc', () {
    test('initial state is FormStatus.initial', () {
      expect(bloc.state.status, FormStatus.initial);
    });

    group('SaveAccountRequested', () {
      blocTest<AddEditAccountBloc, AddEditAccountState>(
        'emits [submitting, success] when AddAssetAccount succeeds',
        build: () {
          when(() => mockUuid.v4()).thenReturn('1');
          when(() => mockAddAssetAccountUseCase(any()))
              .thenAnswer((_) async => Right(tAccount));
          return bloc;
        },
        act: (bloc) => bloc.add(SaveAccountRequested(
          name: 'Cash',
          type: AssetType.cash,
          initialBalance: 100.0,
        )),
        expect: () => [
          AddEditAccountState(status: FormStatus.submitting),
          AddEditAccountState(status: FormStatus.success),
        ],
        verify: (_) {
          verify(() => mockAddAssetAccountUseCase(any())).called(1);
        },
      );

      blocTest<AddEditAccountBloc, AddEditAccountState>(
        'emits [submitting, error] when AddAssetAccount fails',
        build: () {
          when(() => mockUuid.v4()).thenReturn('1');
          when(() => mockAddAssetAccountUseCase(any()))
              .thenAnswer((_) async => Left(CacheFailure('Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(SaveAccountRequested(
          name: 'Cash',
          type: AssetType.cash,
          initialBalance: 100.0,
        )),
        expect: () => [
          AddEditAccountState(status: FormStatus.submitting),
          AddEditAccountState(
            status: FormStatus.error,
            errorMessage: 'Database Error: Could not save account. Error',
          ),
        ],
      );

      blocTest<AddEditAccountBloc, AddEditAccountState>(
        'emits [submitting, success] when UpdateAssetAccount succeeds',
        build: () {
          // Re-instantiate with initial account
          bloc = AddEditAccountBloc(
            addAssetAccountUseCase: mockAddAssetAccountUseCase,
            updateAssetAccountUseCase: mockUpdateAssetAccountUseCase,
            initialAccount: tAccount,
            uuid: mockUuid,
          );
          when(() => mockUpdateAssetAccountUseCase(any()))
              .thenAnswer((_) async => Right(tAccount));
          return bloc;
        },
        act: (bloc) => bloc.add(SaveAccountRequested(
          name: 'Cash',
          type: AssetType.cash,
          initialBalance: 100.0,
          existingAccountId: '1',
        )),
        expect: () => [
          AddEditAccountState(
            status: FormStatus.submitting,
            initialAccount: tAccount,
          ),
          AddEditAccountState(
            status: FormStatus.success,
            initialAccount: tAccount,
          ),
        ],
        verify: (_) {
          verify(() => mockUpdateAssetAccountUseCase(any())).called(1);
        },
      );
    });
  });
}
