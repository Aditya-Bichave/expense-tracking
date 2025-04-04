// lib/features/categories/domain/entities/categorization_status.dart

/// Represents the categorization status of a transaction.
enum CategorizationStatus {
  uncategorized, // Default, needs user action
  needsReview, // SCE suggested, needs user confirmation
  categorized, // Automatically or manually categorized
}

// Helper extension for storing enum as string in Hive/JSON if needed
// (Alternatively, store the index as int)
extension CategorizationStatusExtension on CategorizationStatus {
  String get value {
    switch (this) {
      case CategorizationStatus.uncategorized:
        return 'uncategorized';
      case CategorizationStatus.needsReview:
        return 'needs_review';
      case CategorizationStatus.categorized:
        return 'categorized';
    }
  }

  static CategorizationStatus fromValue(String? value) {
    switch (value) {
      case 'needs_review':
        return CategorizationStatus.needsReview;
      case 'categorized':
        return CategorizationStatus.categorized;
      case 'uncategorized':
      default:
        return CategorizationStatus.uncategorized;
    }
  }
}
