import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupDataUseCase extends Mock implements BackupDataUseCase {}
class MockRestoreDataUseCase extends Mock implements RestoreDataUseCase {}
class MockClearAllDataUseCase extends Mock implements ClearAllDataUseCase {}

class FakeBackupParams extends Fake implements BackupParams {}
class FakeRestoreParams extends Fake implements RestoreParams {}
class FakeNoParams extends Fake implements NoParams {}

void main() {
  late DataManagementBloc bloc;
  late MockBackupDataUseCase mockBackupDataUseCase;
  late MockRestoreDataUseCase mockRestoreDataUseCase;
  late MockClearAllDataUseCase mockClearAllDataUseCase;

  setUpAll(() {
    registerFallbackValue(FakeBackupParams());
    registerFallbackValue(FakeRestoreParams());
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockBackupDataUseCase = MockBackupDataUseCase();
    mockRestoreDataUseCase = MockRestoreDataUseCase();
    mockClearAllDataUseCase = MockClearAllDataUseCase();

    GetIt.I.reset();
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    GetIt.I.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );

    bloc = DataManagementBloc(
      backupDataUseCase: mockBackupDataUseCase,
      restoreDataUseCase: mockRestoreDataUseCase,
      clearAllDataUseCase: mockClearAllDataUseCase,
    );
  });

  tearDown(() {
    bloc.close();
    GetIt.I.reset();
  });

  final tPassword = 'password';

  group('DataManagementBloc', () {
    test('initial state is DataManagementStatus.initial', () {
      expect(bloc.state.status, DataManagementStatus.initial);
    });

    group('BackupRequested', () {
      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, success] when backup succeeds',
        build: () {
          when(() => mockBackupDataUseCase(any()))
              .thenAnswer((_) async => const Right('path/to/backup'));
          return bloc;
        },
        act: (bloc) => bloc.add(BackupRequested(tPassword)),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.success,
            message: 'Backup successful! Saved to: path/to/backup',
          ),
        ],
        verify: (_) {
          verify(() => mockBackupDataUseCase(any())).called(1);
        },
      );

      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, error] when backup fails',
        build: () {
          when(() => mockBackupDataUseCase(any()))
              .thenAnswer((_) async => Left(ServerFailure('Backup Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(BackupRequested(tPassword)),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.error,
            message: 'Backup failed: Backup Error',
          ),
        ],
      );
    });

    group('RestoreRequested', () {
      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, success] when restore succeeds',
        build: () {
          when(() => mockRestoreDataUseCase(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(RestoreRequested(tPassword)),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.success,
            message: 'Restore successful! App will reload data.',
          ),
        ],
        verify: (_) {
          verify(() => mockRestoreDataUseCase(any())).called(1);
        },
      );

      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, error] when restore fails',
        build: () {
          when(() => mockRestoreDataUseCase(any()))
              .thenAnswer((_) async => Left(ServerFailure('Restore Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(RestoreRequested(tPassword)),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.error,
            message: 'Restore failed: Restore Error',
          ),
        ],
      );
    });

    group('ClearDataRequested', () {
      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, success] when clear data succeeds',
        build: () {
          when(() => mockClearAllDataUseCase(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(ClearDataRequested()),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.success,
            message: 'All data cleared successfully!',
          ),
        ],
        verify: (_) {
          verify(() => mockClearAllDataUseCase(any())).called(1);
        },
      );

      blocTest<DataManagementBloc, DataManagementState>(
        'emits [loading, error] when clear data fails',
        build: () {
          when(() => mockClearAllDataUseCase(any()))
              .thenAnswer((_) async => Left(CacheFailure('Clear Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(ClearDataRequested()),
        expect: () => [
          DataManagementState(status: DataManagementStatus.loading),
          DataManagementState(
            status: DataManagementStatus.error,
            message: 'Failed to clear data: Clear Error',
          ),
        ],
      );
    });

    group('ClearDataManagementMessage', () {
      blocTest<DataManagementBloc, DataManagementState>(
        'resets status to initial and clears message',
        build: () => bloc,
        seed: () => DataManagementState(status: DataManagementStatus.success, message: 'Success'),
        act: (bloc) => bloc.add(ClearDataManagementMessage()),
        expect: () => [
          DataManagementState(status: DataManagementStatus.initial, message: null),
        ],
      );
    });
  });
}
