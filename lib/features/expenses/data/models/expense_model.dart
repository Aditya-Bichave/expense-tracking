// lib/features/expenses/data/models/expense_model.dart
// MODIFIED FILE
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
// REMOVED: import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:json_annotation/json_annotation.dart';
// Import CategorizationStatus

part 'expense_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0) // Keep existing typeId
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  // REMOVED old category fields
  // @HiveField(4)
  // final String categoryName;
  // @HiveField(5)
  // final String? subCategoryName;

  @HiveField(4) // Reuse index 4
  @JsonKey(includeIfNull: false) // Don't include if null
  final String? categoryId; // NEW: Link to CategoryModel.id

  @HiveField(5) // Reuse index 5
  @JsonKey(
    defaultValue: 'uncategorized', // Default value for JSON parsing
    toJson: _categorizationStatusToJson,
    fromJson: _categorizationStatusFromJson,
  )
  final String categorizationStatusValue; // NEW: Store enum value string

  @HiveField(6)
  final String accountId; // Keep index 6

  @HiveField(7) // NEW index
  @JsonKey(includeIfNull: false)
  final double? confidenceScoreValue; // NEW: Store confidence score

  @HiveField(8) // NEW index
  @JsonKey(defaultValue: false)
  final bool isRecurring;

  // Helper functions for JSON serialization of enum
  static String _categorizationStatusToJson(String statusValue) => statusValue;
  static String _categorizationStatusFromJson(String? value) =>
      value ?? CategorizationStatus.uncategorized.value;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    // categoryName, subCategoryName REMOVED from constructor
    this.categoryId, // Added
    this.categorizationStatusValue = 'uncategorized', // Added with default
    required this.accountId,
    this.confidenceScoreValue, // Added
    this.isRecurring = false,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryId:
          entity.category?.id, // Get ID from Category entity if available
      categorizationStatusValue: entity.status.value, // Get string value
      accountId: entity.accountId,
      confidenceScoreValue: entity.confidenceScore,
      isRecurring: entity.isRecurring,
    );
  }

  // toEntity now requires Category to be looked up elsewhere based on categoryId
  Expense toEntity() {
    return Expense(
      id: id,
      title: title,
      amount: amount,
      date: date,
      // Category object is NOT constructed here anymore.
      // It will be fetched separately using categoryId by the repository/use care.
      category: null, // Set to null initially
      accountId: accountId,
      status: CategorizationStatusExtension.fromValue(
        categorizationStatusValue,
      ), // Convert string back to enum
      confidenceScore: confidenceScoreValue,
      isRecurring: isRecurring,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
}
