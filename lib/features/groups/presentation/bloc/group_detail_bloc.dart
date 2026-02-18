import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/add_group_expense_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_group_expenses_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_group_members_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_group_usecase.dart';

// Events
abstract class GroupDetailEvent extends Equatable {
  const GroupDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroup extends GroupDetailEvent {
  final String groupId;
  final GroupEntity? group;
  const LoadGroup(this.groupId, {this.group});
  @override
  List<Object?> get props => [groupId, group];
}

class AddExpense extends GroupDetailEvent {
  final GroupExpenseEntity expense;
  const AddExpense(this.expense);
  @override
  List<Object?> get props => [expense];
}

class RefreshGroup extends GroupDetailEvent {
  final String groupId;
  const RefreshGroup(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

// States
abstract class GroupDetailState extends Equatable {
  const GroupDetailState();
  @override
  List<Object?> get props => [];
}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupEntity group;
  final List<GroupMemberEntity> members;
  final List<GroupExpenseEntity> expenses;

  const GroupDetailLoaded({
    required this.group,
    required this.members,
    required this.expenses,
  });

  @override
  List<Object?> get props => [group, members, expenses];

  GroupDetailLoaded copyWith({
    GroupEntity? group,
    List<GroupMemberEntity>? members,
    List<GroupExpenseEntity>? expenses,
  }) {
    return GroupDetailLoaded(
      group: group ?? this.group,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
    );
  }
}

class GroupDetailError extends GroupDetailState {
  final String message;
  const GroupDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  final GetGroupUseCase _getGroupUseCase;
  final GetGroupMembersUseCase _getMembersUseCase;
  final GetGroupExpensesUseCase _getExpensesUseCase;
  final AddGroupExpenseUseCase _addExpenseUseCase;

  GroupDetailBloc({
    required GetGroupUseCase getGroupUseCase,
    required GetGroupMembersUseCase getMembersUseCase,
    required GetGroupExpensesUseCase getExpensesUseCase,
    required AddGroupExpenseUseCase addExpenseUseCase,
  }) : _getGroupUseCase = getGroupUseCase,
       _getMembersUseCase = getMembersUseCase,
       _getExpensesUseCase = getExpensesUseCase,
       _addExpenseUseCase = addExpenseUseCase,
       super(GroupDetailInitial()) {
    on<LoadGroup>(_onLoadGroup);
    on<AddExpense>(_onAddExpense);
    on<RefreshGroup>(_onRefreshGroup);
  }

  Future<void> _onLoadGroup(
    LoadGroup event,
    Emitter<GroupDetailState> emit,
  ) async {
    emit(GroupDetailLoading());
    try {
      GroupEntity? group = event.group;
      if (group == null) {
        final groupResult = await _getGroupUseCase(
          GetGroupParams(event.groupId),
        );
        group = groupResult.fold((l) => null, (r) => r);
      }

      if (group == null) {
        emit(const GroupDetailError("Group not found"));
        return;
      }

      final membersResult = await _getMembersUseCase(
        GetGroupMembersParams(event.groupId),
      );
      final expensesResult = await _getExpensesUseCase(
        GetGroupExpensesParams(event.groupId),
      );

      final members = membersResult.fold(
        (l) => <GroupMemberEntity>[],
        (r) => r,
      );
      final expenses = expensesResult.fold(
        (l) => <GroupExpenseEntity>[],
        (r) => r,
      );

      emit(
        GroupDetailLoaded(group: group, members: members, expenses: expenses),
      );
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<GroupDetailState> emit,
  ) async {
    final result = await _addExpenseUseCase(event.expense);
    result.fold((failure) => emit(GroupDetailError(failure.message)), (
      expense,
    ) {
      if (state is GroupDetailLoaded) {
        final currentState = state as GroupDetailLoaded;
        emit(
          currentState.copyWith(expenses: [expense, ...currentState.expenses]),
        );
      }
    });
  }

  Future<void> _onRefreshGroup(
    RefreshGroup event,
    Emitter<GroupDetailState> emit,
  ) async {
    if (state is GroupDetailLoaded) {
      final currentGroup = (state as GroupDetailLoaded).group;
      add(LoadGroup(currentGroup.id, group: currentGroup));
    }
  }
}
