# Testing Strategy
- To prevent test flakiness related to `DateTime` comparisons with `DateTime.now()` (e.g., in `generate_transactions_on_launch_test.dart`), strip sub-day precision by using `DateTime(now.year, now.month, now.day)` when simulating daily boundaries.
- When firing background sync tasks or other unawaited futures, append `.catchError((e) => log.severe(...))` instead of using `unawaited()` to prevent silent failures and ensure errors are properly logged.

## Pre-commit Steps
1. Make sure to run `dart format .` and `flutter analyze`
2. Make sure to run `flutter test --coverage`
3. Check `test_analysis.py` to see if there are any untested files

