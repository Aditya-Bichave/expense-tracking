## 2024-05-18 - [Dart/Flutter Performance Baseline]
**Learning:** This is a Flutter application using Dart and Blocs for state management. While investigating generic lists/ListViews, we need to focus on Dart-specific performance enhancements like `const` constructors where possible, efficient list building with `ListView.builder` over `ListView` for large datasets, avoiding unnecessary rebuilds using `BlocBuilder` with precise `buildWhen`, and lazy-loading components.
**Action:** Review uses of `ListView` and `SizedBox`/`Padding` to see if they can be optimized to `const`. Look for places where `ListView` is used but could be `ListView.builder`. Check for `Image.network` instead of cached network image.

## 2024-05-18 - [BlocBuilder Optimization]
**Learning:** There are 38 uses of `BlocBuilder` across the application but ZERO uses of `buildWhen`. This means that ANY state change in these Blocs will trigger a rebuild of the widget subtree, even if the relevant parts of the state haven't changed. This is a massive source of unnecessary re-renders in Flutter apps using Bloc.
**Action:** I will find 10 instances of `BlocBuilder` that render large lists or complex UI, and add a `buildWhen` condition to them. This ensures the widgets are only rebuilt when the specific properties they depend on actually change.
