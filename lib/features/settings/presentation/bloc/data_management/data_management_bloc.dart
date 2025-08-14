// lib/features/settings/presentation/bloc/data_management/data_management_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

part 'data_management_event.dart';
part 'data_management_state.dart';

class DataManagementBloc
    extends Bloc<DataManagementEvent, DataManagementState> {
  final BackupDataUseCase _backupDataUseCase;
  final RestoreDataUseCase _restoreDataUseCase;
  final ClearAllDataUseCase _clearAllDataUseCase;

  DataManagementBloc({
    required BackupDataUseCase backupDataUseCase,
    required RestoreDataUseCase restoreDataUseCase,
    required ClearAllDataUseCase clearAllDataUseCase,
  }) : _backupDataUseCase = backupDataUseCase,
       _restoreDataUseCase = restoreDataUseCase,
       _clearAllDataUseCase = clearAllDataUseCase,
       super(const DataManagementState()) {
    on<BackupRequested>(_onBackupRequested);
    on<RestoreRequested>(_onRestoreRequested);
    on<ClearDataRequested>(_onClearDataRequested);
    on<ClearDataManagementMessage>(_onClearMessage);

    log.info("[DataManagementBloc] Initialized.");
  }

  Future<void> _onBackupRequested(
    BackupRequested event,
    Emitter<DataManagementState> emit,
  ) async {
    log.info("[DataManagementBloc] Received BackupRequested event.");
    emit(
      state.copyWith(status: DataManagementStatus.loading, clearMessage: true),
    );
    final result = await _backupDataUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning("[DataManagementBloc] Backup failed: ${failure.message}");
        emit(
          state.copyWith(
            status: DataManagementStatus.error,
            message: 'Backup failed: ${_mapFailureToMessage(failure)}',
          ),
        );
      },
      (messageOrPath) {
        log.info(
          "[DataManagementBloc] Backup successful. Message/Path: $messageOrPath",
        );
        String successMessage = kIsWeb
            ? (messageOrPath ?? 'Backup download initiated!')
            : 'Backup successful! Saved to: ${messageOrPath ?? 'chosen location'}';
        emit(
          state.copyWith(
            status: DataManagementStatus.success,
            message: successMessage,
          ),
        );
        // Reset status after showing message? Maybe not needed immediately.
        // emit(state.copyWith(status: DataManagementStatus.initial));
      },
    );

  }

  Future<void> _onRestoreRequested(
    RestoreRequested event,
    Emitter<DataManagementState> emit,
  ) async {
    log.info("[DataManagementBloc] Received RestoreRequested event.");
    emit(
      state.copyWith(status: DataManagementStatus.loading, clearMessage: true),
    );
    final result = await _restoreDataUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning("[DataManagementBloc] Restore failed: ${failure.message}");
        emit(
          state.copyWith(
            status: DataManagementStatus.error,
            message: 'Restore failed: ${_mapFailureToMessage(failure)}',
          ),
        );
      },
      (_) {
        log.info(
          "[DataManagementBloc] Restore successful. Publishing data change events.",
        );
        emit(
          state.copyWith(
            status: DataManagementStatus.success,
            message: 'Restore successful! App will reload data.',
          ),
        );
        // Publish multiple events to trigger reloads across features
        publishDataChangedEvent(
          type: DataChangeType.account,
          reason: DataChangeReason.added,
        );
        publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        );
        publishDataChangedEvent(
          type: DataChangeType.income,
          reason: DataChangeReason.added,
        );
        // SettingsBloc needs to be reloaded separately by the UI if needed
      },
    );
  }

  Future<void> _onClearDataRequested(
    ClearDataRequested event,
    Emitter<DataManagementState> emit,
  ) async {
    log.info("[DataManagementBloc] Received ClearDataRequested event.");
    emit(
      state.copyWith(status: DataManagementStatus.loading, clearMessage: true),
    );
    final result = await _clearAllDataUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning(
          "[DataManagementBloc] Clear data failed: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: DataManagementStatus.error,
            message: 'Failed to clear data: ${_mapFailureToMessage(failure)}',
          ),
        );
      },
      (_) {
        log.info(
          "[DataManagementBloc] Clear data successful. Publishing data change events.",
        );
        emit(
          state.copyWith(
            status: DataManagementStatus.success,
            message: 'All data cleared successfully!',
          ),
        );
        publishDataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        );
        publishDataChangedEvent(
          type: DataChangeType.account,
          reason: DataChangeReason.deleted,
        );
        publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.deleted,
        );
        publishDataChangedEvent(
          type: DataChangeType.income,
          reason: DataChangeReason.deleted,
        );
      },
    );
  }

  void _onClearMessage(
    ClearDataManagementMessage event,
    Emitter<DataManagementState> emit,
  ) {
    log.info("[DataManagementBloc] Clearing message.");
    // Reset status to initial when clearing message to prevent stale success/error states
    emit(
      state.copyWith(status: DataManagementStatus.initial, clearMessage: true),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    // Simple mapping, can be expanded
    return failure.message;
  }
}
