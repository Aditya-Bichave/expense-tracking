import 'package:equatable/equatable.dart';

// Simple Category for now, can be expanded
enum PredefinedCategory {
  food,
  transport,
  utilities,
  entertainment,
  housing,
  other
}

class Category extends Equatable {
  final String name; // e.g., "Food", "Transport"
  final String? subCategory; // e.g., "Groceries", "Bus", null

  const Category({required this.name, this.subCategory});

  // Helper for dropdowns etc.
  String get displayName => subCategory != null ? '$name > $subCategory' : name;

  // Factory constructor for PredefinedCategory
  factory Category.fromPredefined(PredefinedCategory predefined,
      {String? sub}) {
    String name;
    switch (predefined) {
      case PredefinedCategory.food:
        name = 'Food';
        break;
      case PredefinedCategory.transport:
        name = 'Transport';
        break;
      case PredefinedCategory.utilities:
        name = 'Utilities';
        break;
      case PredefinedCategory.entertainment:
        name = 'Entertainment';
        break;
      case PredefinedCategory.housing:
        name = 'Housing';
        break;
      case PredefinedCategory.other:
        name = 'Other';
        break;
    }
    return Category(name: name, subCategory: sub);
  }

  @override
  List<Object?> get props => [name, subCategory];
}
