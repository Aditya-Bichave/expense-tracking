import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SummaryEvent', () {
    test('LoadSummary supports value comparisons', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 31);
      expect(
        LoadSummary(
          startDate: date1,
          endDate: date2,
          forceReload: true,
          updateFilters: false,
        ),
        equals(
          LoadSummary(
            startDate: date1,
            endDate: date2,
            forceReload: true,
            updateFilters: false,
          ),
        ),
      );
      expect(
        LoadSummary(startDate: date1, endDate: date2),
        isNot(
          equals(
            LoadSummary(startDate: date1, endDate: date2, forceReload: true),
          ),
        ),
      );
    });

    test('ResetState supports value comparisons', () {
      expect(const ResetState(), equals(const ResetState()));
    });
  });
}
