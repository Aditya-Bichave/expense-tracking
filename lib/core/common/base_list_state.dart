// lib/core/common/base_list_state.dart
import 'package:equatable/equatable.dart';

// Base class for Loaded state containing items and filters
abstract class BaseListState<T> extends Equatable {
  final List<T> items;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCategory;
  final String? filterAccountId;

  const BaseListState({
    required this.items,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterAccountId,
  });

  // Helper to check if any filters are active
  bool get filtersApplied =>
      filterStartDate != null ||
      filterEndDate != null ||
      filterCategory != null ||
      filterAccountId != null;

  @override
  List<Object?> get props => [
    items,
    filterStartDate,
    filterEndDate,
    filterCategory,
    filterAccountId,
  ];
}

// Base class for the Loading state
abstract class BaseListLoadingState extends Equatable {
  final bool isReloading;
  const BaseListLoadingState({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

// Base class for the Error state
abstract class BaseListErrorState extends Equatable {
  final String message;
  const BaseListErrorState(this.message);

  @override
  List<Object> get props => [message];
}

// Base class for Initial state
abstract class BaseListInitialState extends Equatable {
  const BaseListInitialState();
  @override
  List<Object?> get props => [];
}
