import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'add_expense_wizard_event.dart';
import 'add_expense_wizard_state.dart';

class AddExpenseWizardBloc
    extends Bloc<AddExpenseWizardEvent, AddExpenseWizardState> {
  final AddExpenseRepository repository;
  final GroupsRepository groupsRepository;
  final String currentUserId;
  final SplitPreviewEngine splitEngine;
  final ImageCompressionService imageCompressionService;
  final SupabaseClient supabase;
  final Uuid uuid;
  final Box<ProfileModel> profileBox;

  AddExpenseWizardBloc({
    required this.repository,
    required this.groupsRepository,
    required this.currentUserId,
    required this.splitEngine,
    required this.imageCompressionService,
    required this.supabase,
    required this.profileBox,
    this.uuid = const Uuid(),
  }) : super(
         AddExpenseWizardState(
           expenseDate: DateTime.now(),
           currentUserId: currentUserId,
           transactionId: uuid.v4(),
         ),
       ) {
    on<WizardStarted>(_onWizardStarted);
    on<AmountChanged>(_onAmountChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<CategorySelected>(_onCategorySelected);
    on<GroupSelected>(_onGroupSelected);
    on<DateChanged>(_onDateChanged);
    on<NotesChanged>(_onNotesChanged);
    on<ReceiptSelected>(_onReceiptSelected);
    on<SplitModeChanged>(_onSplitModeChanged);
    on<SplitValueChanged>(_onSplitValueChanged);
    on<PayerChanged>(_onPayerChanged);
    on<SinglePayerSelected>(_onSinglePayerSelected);
    on<SubmitExpense>(_onSubmitExpense);
  }

  void _onWizardStarted(
    WizardStarted event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    String currency = 'INR';
    final profile = profileBox.get(currentUserId);
    if (profile != null) currency = profile.currency;

    emit(
      state.copyWith(
        status: FormStatus.initial,
        transactionId: uuid.v4(),
        expenseDate: DateTime.now(),
        currency: currency,
      ),
    );
  }

  void _onAmountChanged(
    AmountChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    emit(state.copyWith(amountTotal: event.amount));
    _recalculateSplits(emit);
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        categoryId: event.category.id,
      ),
    );
  }

  Future<void> _onGroupSelected(
    GroupSelected event,
    Emitter<AddExpenseWizardState> emit,
  ) async {
    final group = event.group;
    if (group == null) {
      emit(
        state.copyWith(
          groupId: null,
          selectedGroup: null,
          groupMembers: [],
          splitMode: SplitMode.equal,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedGroup: group,
        groupId: group.id,
        splitMode: SplitMode.equal,
      ),
    );

    final result = await groupsRepository.getGroupMembers(group.id);
    result.fold(
      (failure) => log.warning('Failed to load group members: $failure'),
      (members) {
        emit(state.copyWith(groupMembers: members));
        _setDefaultSplits(emit, members);
      },
    );
  }

  void _setDefaultSplits(
    Emitter<AddExpenseWizardState> emit,
    List<dynamic> members,
  ) {
    final payer = PayerModel(
      userId: currentUserId,
      amountPaid: state.amountTotal,
    );
    final splits = SplitPreviewEngine.calculateEqualSplits(
      state.amountTotal,
      state.groupMembers,
    );

    emit(state.copyWith(payers: [payer], splits: splits, isSplitValid: true));
  }

  void _recalculateSplits(Emitter<AddExpenseWizardState> emit) {
    if (state.groupId == null) return;

    // Recalculate computed amounts
    List<SplitModel> newSplits = [];
    if (state.splitMode == SplitMode.equal) {
      newSplits = SplitPreviewEngine.calculateEqualSplits(
        state.amountTotal,
        state.groupMembers,
      );
    } else if (state.splitMode == SplitMode.percent) {
      newSplits = SplitPreviewEngine.calculatePercentSplits(
        state.amountTotal,
        state.splits,
      );
    } else if (state.splitMode == SplitMode.shares) {
      newSplits = SplitPreviewEngine.calculateShareSplits(
        state.amountTotal,
        state.splits,
      );
    } else {
      // Exact: No auto-calculation on total change
      newSplits = state.splits;
    }

    // Also, if single payer is current user, update their amount
    if (state.payers.length == 1 &&
        state.payers.first.userId == currentUserId) {
      final updatedPayer = PayerModel(
        userId: state.payers.first.userId,
        amountPaid: state.amountTotal,
      );
      emit(state.copyWith(payers: [updatedPayer]));
    }

    emit(state.copyWith(splits: newSplits));
    _validateSplits(emit, newSplits);
  }

  void _validateSplits(
    Emitter<AddExpenseWizardState> emit,
    List<SplitModel> splits,
  ) {
    bool valid = true;
    if (state.splitMode == SplitMode.percent) {
      valid = SplitPreviewEngine.validatePercent(splits);
    } else if (state.splitMode == SplitMode.exact) {
      valid = SplitPreviewEngine.validateExact(splits, state.amountTotal);
    }
    emit(state.copyWith(isSplitValid: valid));
  }

  void _onDateChanged(DateChanged event, Emitter<AddExpenseWizardState> emit) {
    emit(state.copyWith(expenseDate: event.date));
  }

  void _onNotesChanged(
    NotesChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  Future<void> _onReceiptSelected(
    ReceiptSelected event,
    Emitter<AddExpenseWizardState> emit,
  ) async {
    emit(
      state.copyWith(
        isUploadingReceipt: true,
        receiptLocalPath: event.localPath,
      ),
    );

    try {
      final compressedFile = await imageCompressionService.compressImage(
        event.localPath,
      );
      if (compressedFile == null) {
        emit(state.copyWith(isUploadingReceipt: false));
        return;
      }

      final fileExt = compressedFile.path.split('.').last;
      final fileName = '${state.transactionId}.$fileExt';
      final pathPrefix = state.groupId ?? 'personal';
      final uploadPath = '$pathPrefix/$fileName';

      await supabase.storage
          .from('receipts')
          .upload(
            uploadPath,
            File(compressedFile.path),
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage
          .from('receipts')
          .getPublicUrl(uploadPath);

      emit(
        state.copyWith(isUploadingReceipt: false, receiptCloudUrl: publicUrl),
      );
    } catch (e) {
      log.severe('Receipt upload failed: $e');
      emit(state.copyWith(isUploadingReceipt: false));
    }
  }

  void _onSplitModeChanged(
    SplitModeChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    emit(state.copyWith(splitMode: event.mode));

    List<SplitModel> newSplits = [];
    if (event.mode == SplitMode.equal) {
      newSplits = SplitPreviewEngine.calculateEqualSplits(
        state.amountTotal,
        state.groupMembers,
      );
    } else {
      // Init with defaults
      newSplits = state.groupMembers.map((m) {
        return SplitModel(
          userId: m.userId,
          shareType: _getSplitTypeFromMode(event.mode),
          shareValue: event.mode == SplitMode.shares
              ? 1.0
              : (event.mode == SplitMode.percent
                    ? (100.0 / state.groupMembers.length)
                    : 0.0),
          computedAmount: 0.0,
        );
      }).toList();

      if (event.mode == SplitMode.percent) {
        newSplits = SplitPreviewEngine.calculatePercentSplits(
          state.amountTotal,
          newSplits,
        );
      } else if (event.mode == SplitMode.shares) {
        newSplits = SplitPreviewEngine.calculateShareSplits(
          state.amountTotal,
          newSplits,
        );
      }
    }

    emit(state.copyWith(splits: newSplits));
    _validateSplits(emit, newSplits);
  }

  SplitType _getSplitTypeFromMode(SplitMode mode) {
    switch (mode) {
      case SplitMode.equal:
        return SplitType.EQUAL;
      case SplitMode.exact:
        return SplitType.EXACT;
      case SplitMode.percent:
        return SplitType.PERCENT;
      case SplitMode.shares:
        return SplitType.SHARE;
    }
  }

  void _onSplitValueChanged(
    SplitValueChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    final newSplits = state.splits.map((s) {
      if (s.userId == event.userId) {
        return s.copyWith(shareValue: event.value);
      }
      return s;
    }).toList();

    // Recalculate computed amounts
    List<SplitModel> calculatedSplits = newSplits;
    if (state.splitMode == SplitMode.percent) {
      calculatedSplits = SplitPreviewEngine.calculatePercentSplits(
        state.amountTotal,
        newSplits,
      );
    } else if (state.splitMode == SplitMode.shares) {
      calculatedSplits = SplitPreviewEngine.calculateShareSplits(
        state.amountTotal,
        newSplits,
      );
    } else if (state.splitMode == SplitMode.exact) {
      calculatedSplits = newSplits
          .map((s) => s.copyWith(computedAmount: s.shareValue))
          .toList();
    }

    emit(state.copyWith(splits: calculatedSplits));
    _validateSplits(emit, calculatedSplits);
  }

  void _onPayerChanged(
    PayerChanged event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    List<PayerModel> currentPayers = List.from(state.payers);
    final index = currentPayers.indexWhere((p) => p.userId == event.userId);
    if (index >= 0) {
      currentPayers[index] = PayerModel(
        userId: event.userId,
        amountPaid: event.amount,
      );
    } else {
      currentPayers.add(
        PayerModel(userId: event.userId, amountPaid: event.amount),
      );
    }
    emit(state.copyWith(payers: currentPayers));
  }

  void _onSinglePayerSelected(
    SinglePayerSelected event,
    Emitter<AddExpenseWizardState> emit,
  ) {
    final payer = PayerModel(
      userId: event.userId,
      amountPaid: state.amountTotal,
    );
    emit(state.copyWith(payers: [payer]));
  }

  Future<void> _onSubmitExpense(
    SubmitExpense event,
    Emitter<AddExpenseWizardState> emit,
  ) async {
    if (state.amountTotal <= 0) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          errorMessage: "Amount must be > 0",
        ),
      );
      return;
    }
    if (!state.isSplitValid && state.groupId != null) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          errorMessage: "Invalid splits",
        ),
      );
      return;
    }

    emit(state.copyWith(status: FormStatus.processing));

    try {
      AddExpenseWizardState finalState = state;
      // If personal, ensure payers/splits are correct
      if (state.groupId == null) {
        final payer = PayerModel(
          userId: currentUserId,
          amountPaid: state.amountTotal,
        );
        final split = SplitModel(
          userId: currentUserId,
          shareType: SplitType.EQUAL,
          shareValue: 1.0,
          computedAmount: state.amountTotal,
        );
        finalState = state.copyWith(payers: [payer], splits: [split]);
      }

      if (state.description.trim().isEmpty && state.selectedCategory != null) {
        finalState = finalState.copyWith(
          description: state.selectedCategory!.name,
        );
      }

      await repository.createExpense(finalState);
      emit(finalState.copyWith(status: FormStatus.success));
    } catch (e) {
      log.severe("Submit failed: $e");
      emit(
        state.copyWith(status: FormStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
