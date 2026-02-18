# Golden Tests

This directory contains golden tests for the Expense Tracker app.

## Running Golden Tests

To run the golden tests:

```bash
flutter test test/golden
```

## Updating Goldens

If you made valid UI changes and need to update the golden files:

```bash
flutter test --update-goldens test/golden
```

**Note:** Golden files are generated based on your OS and rendering engine. In CI, we run on `ubuntu-latest`. Ideally, generate goldens on Linux or use a Docker container to ensure consistency.
