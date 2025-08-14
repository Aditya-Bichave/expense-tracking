import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupDataUseCase extends Mock implements BackupDataUseCase {}

class MockRestoreDataUseCase extends Mock implements RestoreDataUseCase {}

class MockClearAllDataUseCase extends Mock implements ClearAllDataUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const BackupParams(''));
    registerFallbackValue(const RestoreParams(''));
    registerFallbackValue(const NoParams());
  });

  group('DataManagementBloc', () {
    late MockBackupDataUseCase backup;
    late MockRestoreDataUseCase restore;
    late MockClearAllDataUseCase clear;

    setUp(() {
      backup = MockBackupDataUseCase();
      restore = MockRestoreDataUseCase();
      clear = MockClearAllDataUseCase();
    });

    blocTest<DataManagementBloc, DataManagementState>(
      'calls BackupDataUseCase with password and emits success',
      build: () {
        when(
          () => backup(any()),
        ).thenAnswer((_) async => const Right<Failure, String?>('path'));
        return DataManagementBloc(
          backupDataUseCase: backup,
          restoreDataUseCase: restore,
          clearAllDataUseCase: clear,
        );
      },
      act: (bloc) => bloc.add(const BackupRequested('pwd')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.success,
          message: 'Backup successful! Saved to: path',
        ),
      ],
      verify: (_) {
        final verification = verify(() => backup(captureAny()));
        verification.called(1);
        expect((verification.captured.single as BackupParams).password, 'pwd');
      },
    );

    blocTest<DataManagementBloc, DataManagementState>(
      'calls RestoreDataUseCase with password and emits success',
      build: () {
        when(
          () => restore(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return DataManagementBloc(
          backupDataUseCase: backup,
          restoreDataUseCase: restore,
          clearAllDataUseCase: clear,
        );
      },
      act: (bloc) => bloc.add(const RestoreRequested('pwd')),
      expect: () => [
        const DataManagementState(status: DataManagementStatus.loading),
        const DataManagementState(
          status: DataManagementStatus.success,
          message: 'Restore successful! App will reload data.',
        ),
      ],
      verify: (_) {
        final verification = verify(() => restore(captureAny()));
        verification.called(1);
        expect((verification.captured.single as RestoreParams).password, 'pwd');
      },
    );
  });
}
