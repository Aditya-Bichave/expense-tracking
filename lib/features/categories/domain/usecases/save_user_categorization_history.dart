import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:uuid/uuid.dart'; // For generating ID

// Define input data structure needed - Transaction details relevant for matching
class TransactionMatchData extends Equatable {
  final String? merchantId; // Might be null
  final String description;
  // Add other fields if needed for more complex matching (e.g., amount range)

  const TransactionMatchData({this.merchantId, required this.description});

  @override
  List<Object?> get props => [merchantId, description];
}

class SaveUserCategorizationHistoryUseCase
    implements UseCase<void, SaveUserCategorizationHistoryParams> {
  final UserHistoryRepository repository;
  final Uuid uuid;

  SaveUserCategorizationHistoryUseCase(this.repository, this.uuid);

  @override
  Future<Either<Failure, void>> call(
      SaveUserCategorizationHistoryParams params) async {
    log.info(
        "[SaveUserHistoryUseCase] Executing. Category: ${params.selectedCategory.name}");

    // Determine RuleType and Matcher based on transaction data
    // Prioritize merchant match if available
    RuleType ruleType;
    String matcher;

    if (params.transactionData.merchantId != null &&
        params.transactionData.merchantId!.isNotEmpty) {
      ruleType = RuleType.merchant;
      matcher = params.transactionData.merchantId!;
      log.info(
          "[SaveUserHistoryUseCase] Creating rule based on Merchant ID: $matcher");
    } else {
      ruleType = RuleType.description;
      // Use the description directly, or a simplified/hashed version
      // Hashing reduces storage but prevents easy debugging/viewing of rules.
      // Let's use the raw description for now, truncated if needed.
      matcher =
          params.transactionData.description.trim(); // Consider lowercasing?
      // Optional: Implement hashing or pattern simplification here
      // matcher = _simplifyDescription(params.transactionData.description);
      log.info(
          "[SaveUserHistoryUseCase] Creating rule based on Description: $matcher");
      if (matcher.isEmpty) {
        log.warning(
            "[SaveUserHistoryUseCase] Cannot save history rule: Both merchant and description are empty.");
        return const Left(ValidationFailure(
            "Cannot learn from transaction with empty merchant and description."));
      }
    }

    final newRule = UserHistoryRule(
      id: uuid.v4(), // Generate new ID for the rule entry
      ruleType: ruleType,
      matcher: matcher,
      assignedCategoryId:
          params.selectedCategory.id, // Store the ID of the chosen category
      timestamp: DateTime.now(),
    );

    log.info(
        "[SaveUserHistoryUseCase] Calling repository to save rule ID: ${newRule.id}");
    return await repository.saveRule(newRule);
  }

  // Placeholder for potential description simplification/hashing logic
  // String _simplifyDescription(String description) {
  //   // Remove numbers, excessive whitespace, convert to lowercase, etc.
  //   // Or use a hashing algorithm
  //   return description.toLowerCase().replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  // }
}

class SaveUserCategorizationHistoryParams extends Equatable {
  final TransactionMatchData
      transactionData; // Relevant data from the transaction
  final Category selectedCategory; // The category the user chose

  const SaveUserCategorizationHistoryParams({
    required this.transactionData,
    required this.selectedCategory,
  });

  @override
  List<Object?> get props => [transactionData, selectedCategory];
}
