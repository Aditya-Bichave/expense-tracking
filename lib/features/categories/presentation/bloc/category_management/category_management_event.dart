part of 'category_management_bloc.dart';

abstract class CategoryManagementEvent extends Equatable {
  const CategoryManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryManagementEvent {
  const LoadCategories({this.forceReload = false});
  final bool forceReload;
  @override
  List<Object> get props => [forceReload];
}

class AddCategory extends CategoryManagementEvent {
  final String name;
  final String iconName;
  final String colorHex;
  final CategoryType type; // ADDED: Required type for new category
  final String? parentId;

  const AddCategory({
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.type, // ADDED
    this.parentId,
  });
  @override
  List<Object?> get props => [name, iconName, colorHex, type, parentId]; // ADDED type
}

class UpdateCategory extends CategoryManagementEvent {
  final Category category; // Pass the full updated entity
  const UpdateCategory({required this.category});
  @override
  List<Object> get props => [category];
}

class DeleteCategory extends CategoryManagementEvent {
  final String categoryId;
  const DeleteCategory({required this.categoryId});
  @override
  List<Object> get props => [categoryId];
}

// Optional: Event to clear messages
class ClearCategoryMessages extends CategoryManagementEvent {
  const ClearCategoryMessages();
}
