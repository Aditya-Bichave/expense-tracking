part of 'category_management_bloc.dart';

enum CategoryManagementStatus { initial, loading, loaded, error }

class CategoryManagementState extends Equatable {
  final CategoryManagementStatus status;
  final List<Category> customCategories; // Only custom categories
  final List<Category>
      predefinedCategories; // For reference (e.g., personalization)
  final String? errorMessage;

  const CategoryManagementState({
    this.status = CategoryManagementStatus.initial,
    this.customCategories = const [],
    this.predefinedCategories = const [],
    this.errorMessage,
  });

  CategoryManagementState copyWith({
    CategoryManagementStatus? status,
    List<Category>? customCategories,
    List<Category>? predefinedCategories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryManagementState(
      status: status ?? this.status,
      customCategories: customCategories ?? this.customCategories,
      predefinedCategories: predefinedCategories ?? this.predefinedCategories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, customCategories, predefinedCategories, errorMessage];
}
