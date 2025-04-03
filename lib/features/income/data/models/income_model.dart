// lib/features/income/data/models/income_model.dart
// MODIFIED FILE
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
// REMOVED: import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Import CategorizationStatus

part 'income_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 2) // Keep existing typeId
class IncomeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  // REMOVED old category field
  // @HiveField(4)
  // final String categoryName;

  @HiveField(4) // Reuse index 4
  @JsonKey(includeIfNull: false)
  final String? categoryId; // NEW: Link to CategoryModel.id

  @HiveField(5)
  final String accountId; // Keep index 5

  @HiveField(6)
  final String? notes; // Keep index 6

  @HiveField(7) // NEW Index
  @JsonKey(
      defaultValue: 'uncategorized',
      toJson: _categorizationStatusToJson,
      fromJson: _categorizationStatusFromJson)
  final String categorizationStatusValue; // NEW: Store enum value string

  @HiveField(8) // NEW Index
  @JsonKey(includeIfNull: false)
  final double? confidenceScoreValue; // NEW: Store confidence score

  // Helper functions for JSON serialization of enum
  static String _categorizationStatusToJson(String statusValue) => statusValue;
  static String _categorizationStatusFromJson(String? value) =>
      value ?? CategorizationStatus.uncategorized.value;

  IncomeModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    // categoryName REMOVED from constructor
    this.categoryId, // Added
    this.categorizationStatusValue = 'uncategorized', // Added with default
    required this.accountId,
    this.notes,
    this.confidenceScoreValue, // Added
  });

  factory IncomeModel.fromEntity(Income entity) {
    return IncomeModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryId:
          entity.category?.id, // Get ID from Category entity if available
      categorizationStatusValue: entity.status.value, // Get string value
      accountId: entity.accountId,
      notes: entity.notes,
      confidenceScoreValue: entity.confidenceScore,
    );
  }

  // toEntity now requires Category to be looked up elsewhere based on categoryId
  Income toEntity() {
    return Income(
      id: id,
      title: title,
      amount: amount,
      date: date,
      // Category object is NOT constructed here anymore.
      category: null, // Set to null initially
      accountId: accountId,
      notes: notes,
      status: CategorizationStatusExtension.fromValue(
          categorizationStatusValue), // Convert string back to enum
      confidenceScore: confidenceScoreValue,
    );
  }

  factory IncomeModel.fromJson(Map<String, dynamic> json) =>
      _$IncomeModelFromJson(json);

  Map<String, dynamic> toJson() => _$IncomeModelToJson(this);
}
