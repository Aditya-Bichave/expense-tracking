import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';

class CategorizationSuggestion extends Equatable {
  final Category suggestedCategory;
  final double
      confidenceScore; // Numeric score might be more flexible than enum

  const CategorizationSuggestion({
    required this.suggestedCategory,
    required this.confidenceScore,
  });

  @override
  List<Object?> get props => [suggestedCategory, confidenceScore];
}
