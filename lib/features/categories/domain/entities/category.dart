import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:expense_tracker/core/utils/color_utils.dart'; // Helper for hex parsing (create this next)

class Category extends Equatable {
  final String id; // Predefined name or UUID for custom
  final String name;
  final String iconName; // Asset name or identifier
  final String colorHex; // Stored as hex string (e.g., "#FF00FF")
  final bool isCustom;
  final String? parentCategoryId; // Optional for hierarchy

  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.isCustom,
    this.parentCategoryId,
  });

  // Helper to get the actual Color object
  Color get displayColor {
    return ColorUtils.fromHex(colorHex);
  }

  // Optional: Helper for display name (useful if subcategories are implemented)
  // String get hierarchicalName => parentCategory != null ? '${parentCategory.name} > $name' : name;

  @override
  List<Object?> get props => [
        id,
        name,
        iconName,
        colorHex,
        isCustom,
        parentCategoryId,
      ];

  // Optional: Default 'Uncategorized' category static instance
  static final uncategorized = Category(
    id: 'uncategorized',
    name: 'Uncategorized',
    iconName: 'icon_question_mark', // Define a default icon identifier
    colorHex: '#808080', // Grey
    isCustom: false,
  );
}
