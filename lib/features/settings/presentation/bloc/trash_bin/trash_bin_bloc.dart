import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';

class TrashBinBloc extends Bloc<TrashBinEvent, TrashBinState> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  TrashBinBloc({
    required this.expenseRepository,
    required this.incomeRepository,
  }) : super(TrashBinInitial()) {
    on<LoadTrash>(_onLoadTrash);
    on<RestoreItem>(_onRestoreItem);
    on<PurgeItem>(_onPurgeItem);
  }

  Future<void> _onLoadTrash(
    LoadTrash event,
    Emitter<TrashBinState> emit,
  ) async {
    emit(TrashBinLoading());

    try {
      final expensesResult = await expenseRepository.listDeletedExpenses();
      final incomesResult = await incomeRepository.listDeletedIncomes();

      if (expensesResult.isLeft() || incomesResult.isLeft()) {
        final error = expensesResult.fold(
          (l) => l.message,
          (_) => incomesResult.fold((l) => l.message, (_) => 'Unknown error'),
        );
        emit(TrashBinError(error));
        return;
      }

      final expenseModels = expensesResult.getOrElse(() => []);
      final incomeModels = incomesResult.getOrElse(() => []);

      final items = <TrashItem>[
        for (final e in expenseModels)
          if (e.deletedAt != null)
            TrashItem(
              id: e.id,
              title: e.title,
              amount: e.amount,
              date: e.date,
              deletedAt: e.deletedAt!,
              type: TrashItemType.expense,
            ),
        for (final i in incomeModels)
          if (i.deletedAt != null)
            TrashItem(
              id: i.id,
              title: i.title,
              amount: i.amount,
              date: i.date,
              deletedAt: i.deletedAt!,
              type: TrashItemType.income,
            ),
      ];

      items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

      if (items.isEmpty) {
        emit(TrashBinEmpty());
      } else {
        emit(TrashBinLoaded(items));
      }
    } catch (e) {
      emit(TrashBinError('Failed to load trash: $e'));
    }
  }

  Future<void> _onRestoreItem(
    RestoreItem event,
    Emitter<TrashBinState> emit,
  ) async {
    if (event.type == TrashItemType.expense) {
      final res = await expenseRepository.restoreExpense(event.id);
      res.fold((l) => emit(TrashBinError(l.message)), (_) => add(LoadTrash()));
    } else {
      final res = await incomeRepository.restoreIncome(event.id);
      res.fold((l) => emit(TrashBinError(l.message)), (_) => add(LoadTrash()));
    }
  }

  Future<void> _onPurgeItem(
    PurgeItem event,
    Emitter<TrashBinState> emit,
  ) async {
    if (event.type == TrashItemType.expense) {
      final res = await expenseRepository.purgeExpense(event.id);
      res.fold((l) => emit(TrashBinError(l.message)), (_) => add(LoadTrash()));
    } else {
      final res = await incomeRepository.purgeIncome(event.id);
      res.fold((l) => emit(TrashBinError(l.message)), (_) => add(LoadTrash()));
    }
  }
}
