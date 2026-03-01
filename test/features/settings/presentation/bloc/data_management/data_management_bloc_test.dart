import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';

class MockBackupDataUseCase extends Mock implements BackupDataUseCase {}

class MockRestoreDataUseCase extends Mock implements RestoreDataUseCase {}

class MockClearAllDataUseCase extends Mock implements ClearAllDataUseCase {}

class FakeBackupParams extends Fake implements BackupParams {}

class FakeRestoreParams extends Fake implements RestoreParams {}

void main() {
  late DataManagementBloc bloc;
  late MockBackupDataUseCase mockBackupDataUseCase;
  late MockRestoreDataUseCase mockRestoreDataUseCase;
  late MockClearAllDataUseCase mockClearAllDataUseCase;

  setUpAll(() {
    registerFallbackValue(FakeBackupParams());
    registerFallbackValue(FakeRestoreParams());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockBackupDataUseCase = MockBackupDataUseCase();
    mockRestoreDataUseCase = MockRestoreDataUseCase();
    mockClearAllDataUseCase = MockClearAllDataUseCase();

    bloc = DataManagementBloc(
      backupDataUseCase: mockBackupDataUseCase,
      restoreDataUseCase: mockRestoreDataUseCase,
      clearAllDataUseCase: mockClearAllDataUseCase,
    );
  });

  group('DataManagementBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const DataManagementState());
    });

    blocTest<DataManagementBloc, DataManagementState>(
      'emits loading then success for BackupRequested when successful',
      setUp: () {
        when(
          () => mockBackupDataUseCase(any()),
        ).thenAnswer((_) async => const Right('path/to/backup.json'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const BackupRequested('password')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.success,
          message: 'Backup successful! Saved to: path/to/backup.json',
        ),
      ],
      verify: (_) {
        verify(() => mockBackupDataUseCase(any())).called(1);
      },
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'emits loading then error for BackupRequested when failed',
      setUp: () {
        when(
          () => mockBackupDataUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const BackupRequested('password')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.error,
          message: 'Backup failed: failed',
        ),
      ],
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'emits loading then success for RestoreRequested when successful',
      setUp: () {
        when(
          () => mockRestoreDataUseCase(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const RestoreRequested('password')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.success,
          message: 'Restore successful! App will reload data.',
        ),
      ],
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'emits loading then error for RestoreRequested when failed',
      setUp: () {
        when(
          () => mockRestoreDataUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const RestoreRequested('password')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.error,
          message: 'Restore failed: failed',
        ),
      ],
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'emits loading then success for ClearDataRequested when successful',
      setUp: () {
        when(
          () => mockClearAllDataUseCase(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const ClearDataRequested()),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.success,
          message: 'All data cleared successfully!',
        ),
      ],
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'emits initial state and clears message on ClearDataManagementMessage',
      build: () => bloc,
      seed: () => const DataManagementState(
        status: DataManagementStatus.success,
        message: 'Some success message',
      ),
      act: (bloc) => bloc.add(const ClearDataManagementMessage()),
      expect: () => [
        const DataManagementState(
          status: DataManagementStatus.initial,
          message: null,
        ),
      ],
    );
  });
}
