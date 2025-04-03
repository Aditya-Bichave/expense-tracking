// lib/core/utils/enums.dart
// (Add the new enum to the existing file)

/// Represents the submission status of a form within Add/Edit Blocs.
enum FormStatus { initial, submitting, success, error }

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


// Add other shared enums here if needed