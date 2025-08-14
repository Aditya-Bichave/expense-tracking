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
import 'package:expense_tracker/main.dart' as app_logger;

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

    final rulesOrFailure = await recurringTransactionRepository.getRecurringRules();
    return rulesOrFailure.fold(
      (failure) => Left(failure),
      (rules) async {
        final activeRules = rules.where((rule) => rule.status == RuleStatus.active).toList();

        for (var rule in activeRules) {
          if (rule.nextOccurrenceDate.isBefore(today) || rule.nextOccurrenceDate.isAtSameMomentAs(today)) {
            await _processRule(rule);
          }
        }
        return const Right(null);
      },
    );
  }

  Future<void> _processRule(RecurringRule rule) async {
    final categoryResult =
        await categoryRepository.getCategoryById(rule.categoryId);
    Category? category;
    categoryResult.fold(
      (failure) {
        if (failure is NotFoundFailure) {
          app_logger.log.warning(
              "[GenerateTransactionsOnLaunch] Category with ID '${rule.categoryId}' not found. Continuing with null category.");
          category = null;
        } else {
          app_logger.log.warning(
              "[GenerateTransactionsOnLaunch] Failed to fetch category for rule ${rule.id}: ${failure.message}");
          category = null;
        }
      },
      (cat) => category = cat,
    );

    // 1. Generate transaction
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
      await addExpense(AddExpenseParams(newExpense));
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
      await addIncome(AddIncomeParams(newIncome));
    }

    // 2. Update rule
    final newOccurrencesGenerated = rule.occurrencesGenerated + 1;
    final newNextOccurrenceDate = _calculateNextOccurrence(rule);

    RuleStatus newStatus = rule.status;

    // 3. Check end condition
    bool hasEnded = false;
    if (rule.endConditionType == EndConditionType.afterOccurrences) {
      if (newOccurrencesGenerated >= rule.totalOccurrences!) {
        hasEnded = true;
      }
    } else if (rule.endConditionType == EndConditionType.onDate) {
      if (rule.endDate != null && newNextOccurrenceDate.isAfter(rule.endDate!)) {
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

    await recurringTransactionRepository.updateRecurringRule(updatedRule);
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
        final newDay = rule.dayOfMonth! > daysInMonth ? daysInMonth : rule.dayOfMonth!;
        nextDate = DateTime(newYear, newMonth, newDay);
        break;
      case Frequency.yearly:
        nextDate = DateTime(nextDate.year + rule.interval, nextDate.month, nextDate.day);
        break;
    }
    return nextDate;
  }
}
