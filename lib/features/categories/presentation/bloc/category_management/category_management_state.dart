part of 'category_management_bloc.dart';

enum CategoryManagementStatus { initial, loading, loaded, error }

class CategoryManagementState extends Equatable {
  final CategoryManagementStatus status;
  // Store separate lists
  final List<Category> customExpenseCategories;
  final List<Category> customIncomeCategories;
  final List<Category> predefinedExpenseCategories;
  final List<Category> predefinedIncomeCategories;
  // Keep for potential combined views if needed
  // final List<Category> customCategories;
  // final List<Category> predefinedCategories;
  final String? errorMessage;

  // Helper getters for convenience
  List<Category> get allExpenseCategories =>
      [...predefinedExpenseCategories, ...customExpenseCategories];
  List<Category> get allIncomeCategories =>
      [...predefinedIncomeCategories, ...customIncomeCategories];

  const CategoryManagementState({
    this.status = CategoryManagementStatus.initial,
    this.customExpenseCategories = const [], // Initialize lists
    this.customIncomeCategories = const [],
    this.predefinedExpenseCategories = const [],
    this.predefinedIncomeCategories = const [],
    this.errorMessage,
  });

  CategoryManagementState copyWith({
    CategoryManagementStatus? status,
    List<Category>? customExpenseCategories,
    List<Category>? customIncomeCategories,
    List<Category>? predefinedExpenseCategories,
    List<Category>? predefinedIncomeCategories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryManagementState(
      status: status ?? this.status,
      customExpenseCategories:
          customExpenseCategories ?? this.customExpenseCategories,
      customIncomeCategories:
          customIncomeCategories ?? this.customIncomeCategories,
      predefinedExpenseCategories:
          predefinedExpenseCategories ?? this.predefinedExpenseCategories,
      predefinedIncomeCategories:
          predefinedIncomeCategories ?? this.predefinedIncomeCategories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        customExpenseCategories,
        customIncomeCategories, // Use specific lists in props
        predefinedExpenseCategories, predefinedIncomeCategories,
        errorMessage
      ];
}
