import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';

class AddExpenseWizardState extends Equatable {
  // Screen 1: Numpad
  final double amountTotal;

  // Screen 2: Details
  final String description;
  final String? categoryId;
  final Category? selectedCategory;
  final String? groupId;
  final GroupEntity? selectedGroup;
  final List<GroupMember> groupMembers; // For calculating splits/payers
  final String? receiptLocalPath;
  final String? receiptCloudUrl;
  final bool isUploadingReceipt;
  final DateTime expenseDate;
  final String notes;

  // Screen 3: Splits
  final SplitMode splitMode;
  final List<PayerModel> payers;
  final List<SplitModel> splits;
  final bool isSplitValid; // Calculated by engine

  // Meta
  final FormStatus status;
  final String? errorMessage;
  final String? currentUserId; // Needed for default payers/splits
  final String transactionId;
  final String currency; // Default INR or User's

  const AddExpenseWizardState({
    this.amountTotal = 0.0,
    this.description = '',
    this.categoryId,
    this.selectedCategory,
    this.groupId,
    this.selectedGroup,
    this.groupMembers = const [],
    this.receiptLocalPath,
    this.receiptCloudUrl,
    this.isUploadingReceipt = false,
    required this.expenseDate,
    this.notes = '',
    this.splitMode = SplitMode.equal,
    this.payers = const [],
    this.splits = const [],
    this.isSplitValid = true,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.currentUserId,
    required this.transactionId,
    this.currency = 'INR',
  });

  AddExpenseWizardState copyWith({
    double? amountTotal,
    String? description,
    String? categoryId,
    Category? selectedCategory,
    String? groupId,
    GroupEntity? selectedGroup,
    List<GroupMember>? groupMembers,
    String? receiptLocalPath,
    String? receiptCloudUrl,
    bool? isUploadingReceipt,
    DateTime? expenseDate,
    String? notes,
    SplitMode? splitMode,
    List<PayerModel>? payers,
    List<SplitModel>? splits,
    bool? isSplitValid,
    FormStatus? status,
    String? errorMessage,
    String? currentUserId,
    String? transactionId,
    String? currency,
  }) {
    return AddExpenseWizardState(
      amountTotal: amountTotal ?? this.amountTotal,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      groupId: groupId ?? this.groupId,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      groupMembers: groupMembers ?? this.groupMembers,
      receiptLocalPath: receiptLocalPath ?? this.receiptLocalPath,
      receiptCloudUrl: receiptCloudUrl ?? this.receiptCloudUrl,
      isUploadingReceipt: isUploadingReceipt ?? this.isUploadingReceipt,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      splitMode: splitMode ?? this.splitMode,
      payers: payers ?? this.payers,
      splits: splits ?? this.splits,
      isSplitValid: isSplitValid ?? this.isSplitValid,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUserId: currentUserId ?? this.currentUserId,
      transactionId: transactionId ?? this.transactionId,
      currency: currency ?? this.currency,
    );
  }

  // Helper: To JSON Payload
  Map<String, dynamic> toApiPayload() {
    return {
      'p_group_id': groupId, // Null if personal
      'p_created_by': currentUserId, // Must be set
      'p_transaction_id':
          transactionId, // Optional but good for consistency if allowed
      'p_amount_total': amountTotal,
      'p_currency': currency,
      'p_description': description,
      'p_category_id': categoryId,
      'p_expense_date': expenseDate.toIso8601String(),
      'p_notes': notes,
      'p_receipt_url': receiptCloudUrl, // New Field
      'p_payers': payers.map((e) => e.toJson()).toList(),
      'p_splits': splits.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    amountTotal,
    description,
    categoryId,
    selectedCategory,
    groupId,
    selectedGroup,
    groupMembers,
    receiptLocalPath,
    receiptCloudUrl,
    isUploadingReceipt,
    expenseDate,
    notes,
    splitMode,
    payers,
    splits,
    isSplitValid,
    status,
    errorMessage,
    currentUserId,
    currency,
    transactionId,
  ];
}
