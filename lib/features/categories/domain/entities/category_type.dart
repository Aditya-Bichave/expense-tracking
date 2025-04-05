// Defines the primary financial type of a category
enum CategoryType {
  expense,
  income,
  // transfer, // Add later if needed
}

// Optional: Extension for string conversion if needed for storage/JSON
extension CategoryTypeExtension on CategoryType {
  String toJson() => name; // Use enum name directly for serialization
  static CategoryType fromJson(String json) {
    return CategoryType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => CategoryType.expense, // Default to expense if unknown
    );
  }
}
