import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'category_type.dart'; // Import the new enum

class Category extends Equatable {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final CategoryType type; // ADDED: Type of category
  final bool isCustom;
  final String? parentCategoryId; // For future subcategories

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.type, // ADDED
    required this.isCustom,
    this.parentCategoryId,
  });

  Color get displayColor => ColorUtils.fromHex(colorHex);

  @override
  List<Object?> get props => [
        id,
        name,
        iconName,
        colorHex,
        type, // ADDED
        isCustom,
        parentCategoryId,
      ];

  // Update Uncategorized (make it expense type by default)
  static final uncategorized = Category(
    id: 'uncategorized',
    name: 'Uncategorized',
    iconName: 'question', // Use a name from availableIcons map
    colorHex: '#808080', // Grey
    type: CategoryType.expense, // Default type
    isCustom: false,
  );

  // Helper to create a copy with modified fields
  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    CategoryType? type,
    bool? isCustom,
    ValueGetter<String?>?
        parentCategoryId, // Use ValueGetter for nullable fields
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
      parentCategoryId:
          parentCategoryId != null ? parentCategoryId() : this.parentCategoryId,
    );
  }
}
