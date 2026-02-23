import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:uuid/uuid.dart';

class GenerateTransactionsOnLaunch implements UseCase<void, NoParams> {
  final RecurringTransactionRepository recurringTransactionRepository;
  final CategoryRepository categoryRepository;
  final AddExpenseUseCase addExpense;
  final AddIncomeUseCase addIncome;
  final Uuid uuid;

  GenerateTransactionsOnLaunch({
    required this.recurringTransactionRepository,
    required this.categoryRepository,
    required this.addExpense,
    required this.addIncome,
    required this.uuid,
  });

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Fetch categories and rules in parallel using record destructuring
    final (categoriesResult, rulesResult) = await (
      categoryRepository.getAllCategories(),
      recurringTransactionRepository.getRecurringRules(),
    ).wait;

    return await categoriesResult.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (categories) async {
        final categoryMap = {for (var cat in categories) cat.id: cat};

        return await rulesResult.fold<Future<Either<Failure, void>>>(
          (failure) async => Left(failure),
          (rules) async {
            final activeRules = rules
                .where((rule) => rule.status == RuleStatus.active)
                .toList();

            for (var rule in activeRules) {
              if (rule.nextOccurrenceDate.isBefore(today) ||
                  rule.nextOccurrenceDate.isAtSameMomentAs(today)) {
                final category = categoryMap[rule.categoryId];
                final result = await _processRule(rule, category);
                if (result.isLeft()) {
                  return result;
                }
              }
            }
            return const Right(null);
          },
        );
      },
    );
  }

  Future<Either<Failure, void>> _processRule(
    RecurringRule rule,
    Category? category,
  ) async {
    // 1. Generate transaction
    late Either<Failure, void> transactionResult;
    if (rule.transactionType == TransactionType.expense) {
      final newExpense = Expense(
        id: uuid.v4(),
        title: rule.description,
        amount: rule.amount,
        date: rule.nextOccurrenceDate,
        category: category,
        accountId: rule.accountId,
        isRecurring: true,
      );
      transactionResult = await addExpense(AddExpenseParams(newExpense));
    } else {
      final newIncome = Income(
        id: uuid.v4(),
        title: rule.description,
        amount: rule.amount,
        date: rule.nextOccurrenceDate,
        category: category,
        accountId: rule.accountId,
        notes: '',
        isRecurring: true,
      );
      transactionResult = await addIncome(AddIncomeParams(newIncome));
    }

    return await transactionResult.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (_) async {
        // 2. Update rule
        final newOccurrencesGenerated = rule.occurrencesGenerated + 1;
        final newNextOccurrenceDate = _calculateNextOccurrence(rule);

        RuleStatus newStatus = rule.status;

        // 3. Check end condition with safe null checks
        bool hasEnded = false;
        if (rule.endConditionType == EndConditionType.afterOccurrences) {
          if (rule.totalOccurrences != null &&
              newOccurrencesGenerated >= rule.totalOccurrences!) {
            hasEnded = true;
          }
        } else if (rule.endConditionType == EndConditionType.onDate) {
          if (rule.endDate != null &&
              newNextOccurrenceDate.isAfter(rule.endDate!)) {
            hasEnded = true;
          }
        }

        if (hasEnded) {
          newStatus = RuleStatus.completed;
        }

        final updatedRule = rule.copyWith(
          status: newStatus,
          nextOccurrenceDate: newNextOccurrenceDate,
          occurrencesGenerated: newOccurrencesGenerated,
        );
        final updateResult = await recurringTransactionRepository
            .updateRecurringRule(updatedRule);
        return updateResult;
      },
    );
  }

  DateTime _calculateNextOccurrence(RecurringRule rule) {
    DateTime nextDate = rule.nextOccurrenceDate;
    switch (rule.frequency) {
      case Frequency.daily:
        nextDate = nextDate.add(Duration(days: rule.interval));
        break;
      case Frequency.weekly:
        nextDate = nextDate.add(Duration(days: 7 * rule.interval));
        break;
      case Frequency.monthly:
        var newMonth = nextDate.month + rule.interval;
        var newYear = nextDate.year;
        while (newMonth > 12) {
          newMonth -= 12;
          newYear++;
        }
        final daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
        final targetDay = rule.dayOfMonth ?? rule.startDate.day;
        final newDay = targetDay > daysInMonth ? daysInMonth : targetDay;
        nextDate = DateTime(newYear, newMonth, newDay);
        break;
      case Frequency.yearly:
        final targetYear = nextDate.year + rule.interval;
        final targetMonth = nextDate.month;
        final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay = nextDate.day > daysInTargetMonth
            ? daysInTargetMonth
            : nextDate.day;
        nextDate = DateTime(targetYear, targetMonth, targetDay);
        break;
    }
    return nextDate;
  }
}
