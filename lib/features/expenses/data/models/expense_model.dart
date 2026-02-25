import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  @JsonKey(includeIfNull: false)
  final String? categoryId;

  @HiveField(5)
  @JsonKey(
    defaultValue: 'uncategorized',
    toJson: _categorizationStatusToJson,
    fromJson: _categorizationStatusFromJson,
  )
  final String categorizationStatusValue;

  @HiveField(6)
  final String accountId;

  @HiveField(7)
  @JsonKey(includeIfNull: false)
  final double? confidenceScoreValue;

  @HiveField(8)
  @JsonKey(defaultValue: false)
  final bool isRecurring;

  @HiveField(9)
  @JsonKey(includeIfNull: false)
  final String? merchantId;

  // New Fields for Split Brain / Group Expenses
  @HiveField(10)
  @JsonKey(includeIfNull: false)
  final String? groupId;

  @HiveField(11)
  @JsonKey(includeIfNull: false)
  final String? createdBy;

  @HiveField(12)
  @JsonKey(defaultValue: 'USD')
  final String currency;

  @HiveField(13)
  @JsonKey(includeIfNull: false)
  final String? notes;

  // Audit Fixes
  @HiveField(14)
  @JsonKey(includeIfNull: false)
  final String? receiptUrl;

  @HiveField(15)
  @JsonKey(includeIfNull: false)
  final String? clientGeneratedId;

  // Not storing lists in Hive/JSON by default to avoid complexity without generator
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<ExpensePayer> payers;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<ExpenseSplit> splits;

  static String _categorizationStatusToJson(String statusValue) => statusValue;
  static String _categorizationStatusFromJson(String? value) =>
      value ?? CategorizationStatus.uncategorized.value;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categorizationStatusValue = 'uncategorized',
    required this.accountId,
    this.confidenceScoreValue,
    this.isRecurring = false,
    this.merchantId,
    this.groupId,
    this.createdBy,
    this.currency = 'USD',
    this.notes,
    this.payers = const [],
    this.splits = const [],
    this.receiptUrl,
    this.clientGeneratedId,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryId: entity.category?.id,
      categorizationStatusValue: entity.status.value,
      accountId: entity.accountId,
      confidenceScoreValue: entity.confidenceScore,
      isRecurring: entity.isRecurring,
      merchantId: entity.merchantId,
      groupId: entity.groupId,
      createdBy: entity.createdBy,
      currency: entity.currency,
      notes: entity.notes,
      payers: entity.payers,
      splits: entity.splits,
      receiptUrl: entity.receiptUrl,
      clientGeneratedId: entity.clientGeneratedId,
    );
  }

  Expense toEntity() {
    return Expense(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: null,
      accountId: accountId,
      status: CategorizationStatusExtension.fromValue(
        categorizationStatusValue,
      ),
      confidenceScore: confidenceScoreValue,
      isRecurring: isRecurring,
      merchantId: merchantId,
      groupId: groupId,
      createdBy: createdBy,
      currency: currency,
      notes: notes,
      payers: payers,
      splits: splits,
      receiptUrl: receiptUrl,
      clientGeneratedId: clientGeneratedId,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

  /// Converts the model to the JSON payload required by the 'create_expense_transaction' RPC.
  Map<String, dynamic> toRpcJson() {
    return {
      'p_group_id': groupId,
      'p_created_by': createdBy,
      'p_amount_total': amount,
      'p_currency': currency,
      'p_description': title,
      'p_category_id': categoryId,
      'p_expense_date': date.toIso8601String(),
      'p_notes': notes,
      'p_receipt_url': receiptUrl, // Pass receipt URL
      'p_client_generated_id': clientGeneratedId, // Pass idempotency key
      'p_payers': payers
          .map((p) => {'user_id': p.userId, 'amount_paid': p.amountPaid})
          .toList(),
      'p_splits': splits
          .map(
            (s) => {
              'user_id': s.userId,
              'share_type': s.shareType.value,
              'share_value': s.shareValue,
              'computed_amount': s.computedAmount,
            },
          )
          .toList(),
    };
  }
}
