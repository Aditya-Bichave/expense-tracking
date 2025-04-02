import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Import Failure type
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart'; // Import the use case

// Link the state and event files
part 'summary_event.dart';
part 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetExpenseSummaryUseCase _getExpenseSummaryUseCase; // Dependency

  SummaryBloc({required GetExpenseSummaryUseCase getExpenseSummaryUseCase})
      : _getExpenseSummaryUseCase = getExpenseSummaryUseCase,
        super(SummaryInitial()) {
    // Set initial state
    // Register the event handler for LoadSummary event
    on<LoadSummary>(_onLoadSummary);
  }

  // Handler function for the LoadSummary event
  Future<void> _onLoadSummary(
      LoadSummary event, Emitter<SummaryState> emit) async {
    emit(SummaryLoading()); // Emit loading state immediately

    // Create parameters for the use case from the event data
    final params = GetSummaryParams(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    // Execute the use case
    final result = await _getExpenseSummaryUseCase(params);

    // Handle the result (Either<Failure, ExpenseSummary>)
    result.fold(
      // If Left (Failure)
      (failure) => emit(SummaryError(_mapFailureToMessage(failure))),
      // If Right (Success)
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  // Helper function to convert Failure objects to user-friendly strings
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Could not load summary from local data. ${failure.message}';
      // Add other failure types if needed (e.g., ServerFailure for cloud sync)
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
