#!/bin/bash

# Remove previously added // coverage:ignore-line
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/dashboard/presentation/pages/dashboard_page.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/main.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/auth/presentation/pages/lock_screen.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/core/sync/sync_service.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/accounts/presentation/pages/accounts_tab_page.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/accounts/presentation/pages/account_list_page.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart
sed -i 's/ \/\/ coverage:ignore-line//g' lib/features/reports/presentation/widgets/report_filter_controls.dart
