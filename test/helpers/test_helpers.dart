import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

class Testhelpers {
  static void registerFallbacks() {
    registerFallbackValue(const CategoryManagementInitial());
    registerFallbackValue(const AddCategory(
      name: 'name',
      categoryType: CategoryType.expense,
      icon: Icons.abc,
      color: Colors.black,
    ));
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(const GoalListInitial());
    registerFallbackValue(const AddGoal(
      name: 'name',
      targetAmount: 100,
      icon: Icons.abc,
    ));
    registerFallbackValue(const LogContributionInitial());
    registerFallbackValue(const SaveContribution(amount: 100, date: null));
    registerFallbackValue(BudgetType.overall);
    registerFallbackValue(FakeCategoryManagementEvent());
    registerFallbackValue(FakeGoalListEvent());
    registerFallbackValue(FakeLogContributionEvent());
    registerFallbackValue(FakeTransactionEntity());
    registerFallbackValue(FakeTransaction());
    registerFallbackValue(FakeCategory());
    registerFallbackValue(FakeGoal());
  }
}

class FakeBuildContext extends Fake implements BuildContext {}

class FakeCategoryManagementEvent extends Fake implements CategoryManagementEvent {}

class FakeGoalListEvent extends Fake implements GoalListEvent {}

class FakeLogContributionEvent extends Fake implements LogContributionEvent {}

class FakeTransactionEntity extends Fake implements TransactionEntity {}

class FakeTransaction extends Fake implements Transaction {}

class FakeCategory extends Fake implements Category {}

class FakeGoal extends Fake implements Goal {}
