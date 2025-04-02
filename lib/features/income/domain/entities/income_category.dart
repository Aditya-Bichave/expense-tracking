import 'package:equatable/equatable.dart';

// Using an enum for predefined categories for now
enum PredefinedIncomeCategory {
  salary,
  bonus,
  freelance,
  gift,
  interest,
  other
}

class IncomeCategory extends Equatable {
  final String name; // e.g., "Salary", "Freelance"

  const IncomeCategory({required this.name});

  factory IncomeCategory.fromPredefined(PredefinedIncomeCategory predefined) {
    String name;
    switch (predefined) {
      case PredefinedIncomeCategory.salary:
        name = 'Salary';
        break;
      case PredefinedIncomeCategory.bonus:
        name = 'Bonus';
        break;
      case PredefinedIncomeCategory.freelance:
        name = 'Freelance';
        break;
      case PredefinedIncomeCategory.gift:
        name = 'Gift';
        break;
      case PredefinedIncomeCategory.interest:
        name = 'Interest';
        break;
      case PredefinedIncomeCategory.other:
        name = 'Other';
        break;
    }
    return IncomeCategory(name: name);
  }

  @override
  List<Object?> get props => [name];
}
