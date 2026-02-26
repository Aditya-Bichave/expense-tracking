# UI Audit Report

## Detected Structure Summary
- **App Entrypoint**: `lib/main.dart`
- **App Type**: `MaterialApp.router`
- **Theme Definition**: `lib/core/theme/app_theme.dart` (`AppTheme.buildTheme`)
- **Shared Widgets**: `lib/core/widgets/`
- **Route Names**: `lib/router.dart` (`AppRouter`)
- **Feature Modules**: `lib/features/`
- **UI Kit Placement**: `lib/ui_kit/`

## UI Pattern Counts
- **EdgeInsets/SizedBox**: 593
- **Colors Usage**: 148
- **Standard Buttons**: 120
- **Spacing 16**: 90
- **Spacing 8**: 89
- **TextStyle**: 87
- **BorderRadius**: 77
- **ListTile**: 66
- **Hex Color**: 37
- **Spacing 24**: 36
- **TextField**: 33
- **Container as Card**: 22
- **BoxShadow/Elevation**: 21
- **BottomSheet**: 11
- **TextTheme Override**: 9

## Top 10 UI Hotspots
1. `lib/features/add_expense/presentation/widgets/details_screen.dart` (Total: 35)
2. `lib/features/goals/presentation/pages/goal_detail_page.dart` (Total: 30)
3. `lib/features/reports/presentation/widgets/report_filter_controls.dart` (Total: 29)
4. `lib/core/theme/app_theme.dart` (Total: 28)
5. `lib/features/add_expense/presentation/widgets/split_screen.dart` (Total: 27)
6. `lib/core/screens/initial_setup_screen.dart` (Total: 27)
7. `lib/features/budgets/presentation/pages/budget_detail_page.dart` (Total: 26)
8. `lib/features/goals/presentation/widgets/log_contribution_sheet.dart` (Total: 25)
9. `lib/features/accounts/presentation/pages/accounts_tab_page.dart` (Total: 25)
10. `lib/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart` (Total: 23)

## Migration Difficulty
- **High**: `add_expense/details_screen.dart` (Complex form logic + heavily styled)
- **Medium**: `goals/goal_detail_page.dart` (Standard layout but many widgets)
- **Low**: `dashboard/widgets/asset_distribution_pie_chart.dart` (Isolated component)
